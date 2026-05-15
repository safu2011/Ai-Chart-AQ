import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants/app_constants.dart';

/// Centralises all AdMob logic. Initialise once at app startup:
///   await AdService.instance.init();
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _interstitialReady = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
  }

  // ── Banner ────────────────────────────────────────────────────────────────

  /// Returns a configured [BannerAd]. Caller must dispose() when done.
  BannerAd createBanner({AdSize size = AdSize.banner}) {
    return BannerAd(
      adUnitId: Platform.isAndroid
          ? AppConstants.admobBannerAndroid
          : AppConstants.admobBannerIos,
      size: size,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? AppConstants.admobInterstitialAndroid
          : AppConstants.admobInterstitialIos,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _interstitialReady = false;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
              _interstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) => _interstitialReady = false,
      ),
    );
  }

  /// Shows the interstitial if ready. Safe to call even if not ready.
  Future<void> showInterstitial() async {
    if (_interstitialReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    }
  }

  bool get isInterstitialReady => _interstitialReady;
}

// ── Embeddable Banner Widget ──────────────────────────────────────────────────

/// Drop-in banner ad widget. Handles lifecycle internally.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = AdService.instance.createBanner()
      ..load().then((_) {
        if (mounted) setState(() => _loaded = true);
      });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
