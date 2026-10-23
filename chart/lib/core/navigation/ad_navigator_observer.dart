import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/providers.dart';
import '../../main.dart' show navigatorKey;
import '../../providers/ads_provider.dart';

/// Runs the interstitial counter check on EVERY screen change in the app —
/// forward (push / pushReplacement) and backward (pop: system back, app-bar
/// back, swipe-back, programmatic pop).
///
/// It calls [AdsProvider.loadAndShowInterstitialAd] WITHOUT
/// `showAdWithoutCounterCheck`, so each screen change increments
/// `userInteractionCounter` and the existing counter limit / timer gate in
/// AdsProvider decides whether an ad is actually shown.
///
/// Only full-screen page routes are counted. Dialogs, bottom sheets and menus
/// (PopupRoutes) are ignored, as is the very first route (splash).
class AdNavigatorObserver extends NavigatorObserver {
  /// Route name given to routes that open [PaywallScreen]. PaywallScreen
  /// already shows its own unconditional interstitial in dispose() for
  /// non-Pro users, so closing it must not trigger a second one here.
  static const String paywallRouteName = '/paywall';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) return; // initial route (splash)
    if (route is! PageRoute) return;
    _checkAd();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == null || newRoute is! PageRoute) return;
    _checkAd();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) return;
    if (route is! PageRoute) return;
    if (route.settings.name == paywallRouteName && !_isPro()) {
      // PaywallScreen.dispose() already shows an interstitial for non-Pro.
      return;
    }
    _checkAd();
  }

  bool _isPro() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    return ctx.read<SubscriptionProvider>().isPro;
  }

  void _checkAd() {
    // Defer to after the frame so we never trigger an ad in the middle of the
    // navigator's own build/transition setup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext == null) return;
      AdsProvider.getProvider().loadAndShowInterstitialAd(() {});
    });
  }
}
