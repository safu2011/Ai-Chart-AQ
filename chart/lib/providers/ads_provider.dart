import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/providers.dart';
import '../main.dart';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
// Note: ad unit IDs and ad-placement config no longer come from Remote Config
// (see _kLocalRealAdsJson / _kLocalAdsConfigJson below), so they no longer
// need SharedPreferences-cache keys. SHOW_ADS is still remote-driven.
const String _kShowAds = 'rc_show_ads';
// Credit / API key keys
const String _kChabbi = 'rc_chabbi';
const String _kWeeklyCredits = 'rc_weekly_credits';
const String _kMonthlyCredits = 'rc_monthly_credits';
const String _kYearlyCredits = 'rc_yearly_credits';

// ─── Locally-bundled ad configuration ─────────────────────────────────────
// Ad unit IDs and ad-placement rules used to be fetched from Remote Config
// keys "Real_Ads" / "Ads_configuration". Per product decision, they are now
// parsed from these local JSON blobs so ad loading/placement NEVER waits on
// a network Remote Config fetch. Only Remote Config-only values (chabbi API
// key, credit amounts, SHOW_ADS / show_remote_paywall flags) still come from
// Remote Config, fetched in parallel in the background (see
// _fetchRemoteConfigInBackground below).
const String _kLocalRealAdsJson = '''
{
  "androidAdId": "ca-app-pub-6600265429238791~5045662284",
  "androidInterstitialId": "ca-app-pub-6600265429238791/2574723257",
  "androidNativeId": "ca-app-pub-6600265429238791/8948559914",
  "androidAppOpenId": "ca-app-pub-6600265429238791/1397372955",
  "androidBannerId": "ca-app-pub-6600265429238791/1696755858",
  "androidBannerIdCollapsable": "ca-app-pub-6600265429238791/1696755858",
  "androidRewardAdId": "ca-app-pub-6600265429238791/1505184160"
}
''';

const String _kLocalAdsConfigJson = '''
{
  "userInteractionCounterLimit": 3,
  "interstital_timer_in_seconds": 1,
  "ads_show_counter_limit": 1000,
  "ads_clicked_counter_limit": 10,
  "splash_screen_continue_ad_type": 1,
  "splash_screen_bottom_ad": 1,
  "on_boarding_screen_bottom_ad": 5,
  "home_screen_middle": 5,
  "history_screen_top": 1,
  "alerts_screen_top": 5,
  "settings_screen_bottom": 0,
  "live_chart_screen_top": 5,
  "analysis_result_screen_middle": 5,
  "exit_screen_top": 1
}
''';

class AdsProvider extends ChangeNotifier {
  static bool isShowPersonalizedAd = true;
  static bool SHOW_ADS = true;
  bool show_remote_paywall = false;

  FirebaseRemoteConfig? remoteConfig;

  // ── Default ad unit IDs (test IDs — replaced from Remote Config) ──────────
  String androidAdId = 'ca-app-pub-3940256099942544~3347511713';
  String androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  String androidNativeId = 'ca-app-pub-3940256099942544/2247696110';
  String androidAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  String androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  String androidBannerIdCollapsable = 'ca-app-pub-3940256099942544/9214589741';
  String androidRewardAdId = 'ca-app-pub-3940256099942544/5224354917';

  // ── Ad type constants ─────────────────────────────────────────────────────
  int NO_AD = 0;
  int FULL_BANNER_AD = 1;
  int LARGE_BANNER_AD = 2;
  int COLLAPSABLE_BANNER_AD_TOP = 3;
  int COLLAPSABLE_BANNER_AD_BOTTOM = 4;
  int SMALL_NATIVE_AD = 5;
  int MEDIUM_NATIVE_AD = 6;

  // ── Remote-config ad-slot values (screen → ad type) ──────────────────────
  int ads_show_counter_limit = 10;
  int interstital_timer_in_seconds = 5;
  int interstital_ad_loading_screen_time_in_sec = 2;
  int ads_clicked_counter_limit = 10;
  int splash_screen_continue_ad_type = 2;
  int splash_screen_bottom_ad = 0;
  int on_boarding_screen_bottom_ad = 0;

  // Chart-app specific screen slots
  int home_screen_middle = 0;
  int history_screen_top = 0;
  int alerts_screen_top = 0;
  int settings_screen_bottom = 0;
  int live_chart_screen_top = 0;
  int analysis_result_screen_middle = 0;
  int exit_screen_top = 0;

  AppOpenAdManager? appOpenAdManager;

  InterstitialAd? _interstitialAd;
  RewardedAd? rewardedAd;

  // Preloaded native ad for the home screen (requirement: pre-load
  // home_screen_middle on splash so it's ready the instant Home opens).
  NativeAd? _preloadedHomeNativeAd;
  bool _preloadingHomeNativeAd = false;

  bool isInterstitialAdLoading = false;
  bool isRewardedAdLoading = false;
  int adLoadedCount = 0;
  int adLoadedLimit = 20;

  int adsShownCounter = 0;
  int adsClickedCounter = 0;

  static int userInteractionCounter = 0;
  static int userInteractionCounterLimit = 4;

  DateTime lastInterstitialAdShownDateTime = DateTime.now();

  static final AdRequest request = AdRequest(
    keywords: <String>['finance', 'crypto', 'trading'],
    contentUrl: 'http://aichartanalyzer.com',
    nonPersonalizedAds: isShowPersonalizedAd,
  );

  bool isRewardAdLoading = false;

  static bool loadAdsOnStart = false;

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<bool> initialize(BuildContext context, {bool? showTestAds}) async {
    // Ad unit IDs + ad placement rules are parsed from the local JSON blobs
    // immediately — this never waits on a network call.
    _applyLocalAdIds();
    _applyLocalAdsConfig();

    if (Platform.isAndroid && SHOW_ADS) {
      await setAdMobAppId();
    }

    appOpenAdManager = AppOpenAdManager(androidAppOpenId);

    // Remote Config is only used for chabbi/credits/SHOW_ADS/show_remote_paywall
    // now, and it is fetched in the background in parallel — it is intentionally
    // NOT awaited here so it can never delay ad loading or ad placement.
    // ignore: unawaited_futures
    _fetchRemoteConfigInBackground(context, showTestAds: showTestAds);

    if (await ConsentManager.canRequestAds()) {
      if (splash_screen_continue_ad_type == 2) {
        print("MyLog Loading loadApOpenAd");
        appOpenAdManager?.loadApOpenAd(null);
      }
      // Always keep an interstitial preloaded across the whole app so it can
      // be shown instantly wherever it's needed (splash, paywall, every-3-clicks).
      print("MyLog Preloading interstitial for entire app");
      loadInterstitialAd(null);
      // Preload the home screen native ad so it's ready the instant Home opens.
      preloadHomeScreenNativeAd(context);
    } else {
      loadAdsOnStart = true;
    }

    notifyListeners();
    return true;
  }

  void _applyLocalAdIds() {
    final Map<String, dynamic> idsMap = jsonDecode(_kLocalRealAdsJson);
    androidAdId = idsMap["androidAdId"] ?? androidAdId;
    androidInterstitialId =
        idsMap["androidInterstitialId"] ?? androidInterstitialId;
    androidNativeId = idsMap["androidNativeId"] ?? androidNativeId;
    androidAppOpenId = idsMap["androidAppOpenId"] ?? androidAppOpenId;
    androidBannerId = idsMap["androidBannerId"] ?? androidBannerId;
    androidBannerIdCollapsable =
        idsMap["androidBannerIdCollapsable"] ?? androidBannerIdCollapsable;
    androidRewardAdId = idsMap["androidRewardAdId"] ?? androidRewardAdId;
    print("MyLog Ad unit IDs parsed locally (no Remote Config wait): $idsMap");
  }

  void _applyLocalAdsConfig() {
    final Map<String, dynamic> jsonMap = jsonDecode(_kLocalAdsConfigJson);
    userInteractionCounterLimit =
        jsonMap["userInteractionCounterLimit"] ?? userInteractionCounterLimit;
    interstital_timer_in_seconds = jsonMap["interstital_timer_in_seconds"] ??
        interstital_timer_in_seconds;
    ads_show_counter_limit =
        jsonMap["ads_show_counter_limit"] ?? ads_show_counter_limit;
    ads_clicked_counter_limit =
        jsonMap["ads_clicked_counter_limit"] ?? ads_clicked_counter_limit;
    splash_screen_continue_ad_type = jsonMap["splash_screen_continue_ad_type"] ??
        splash_screen_continue_ad_type;
    splash_screen_bottom_ad =
        jsonMap["splash_screen_bottom_ad"] ?? splash_screen_bottom_ad;
    on_boarding_screen_bottom_ad =
        jsonMap["on_boarding_screen_bottom_ad"] ?? on_boarding_screen_bottom_ad;
    home_screen_middle = jsonMap["home_screen_middle"] ?? home_screen_middle;
    history_screen_top = jsonMap["history_screen_top"] ?? history_screen_top;
    alerts_screen_top = jsonMap["alerts_screen_top"] ?? alerts_screen_top;
    settings_screen_bottom =
        jsonMap["settings_screen_bottom"] ?? settings_screen_bottom;
    live_chart_screen_top =
        jsonMap["live_chart_screen_top"] ?? live_chart_screen_top;
    analysis_result_screen_middle = jsonMap["analysis_result_screen_middle"] ??
        analysis_result_screen_middle;
    exit_screen_top = jsonMap["exit_screen_top"] ?? exit_screen_top;
    print(
        "MyLog Ads placement config parsed locally (no Remote Config wait): $jsonMap");
  }

  // ── Preloaded home-screen native ad ───────────────────────────────────────
  Future<void> preloadHomeScreenNativeAd(BuildContext ctx) async {
    if (!SHOW_ADS) return;
    if (home_screen_middle != SMALL_NATIVE_AD &&
        home_screen_middle != MEDIUM_NATIVE_AD) {
      return;
    }
    if (_preloadedHomeNativeAd != null || _preloadingHomeNativeAd) return;
    _preloadingHomeNativeAd = true;
    print("MyLog Preloading home_screen_middle native ad");
    final ad = await _loadCustomNativeAd(ctx, androidNativeId);
    _preloadedHomeNativeAd = ad;
    _preloadingHomeNativeAd = false;
    print("MyLog home_screen_middle native ad preloaded = ${ad != null}");
  }

  Future<void> setAdMobAppId() async {
    try {
      const MethodChannel('app/method_channel')
          .invokeMethod('changeApplicationId', {"id": androidAdId});
    } on PlatformException catch (e) {
      print("MyLog error in platform invoke $e");
    }
  }

  // ── Interstitial ───────────────────────────────────────────────────────────
  void loadInterstitialAd(Function? functionToTrigger, {String? adId}) {
    print("MyLog loadInterstitialAd called SHOW_ADS= $SHOW_ADS");
    if (SHOW_ADS) {
      if (adsShownCounter > ads_show_counter_limit) {
        isInterstitialAdLoading = false;
        return;
      }
      if (isInterstitialAdLoading) {
        if (functionToTrigger != null) functionToTrigger();
        return;
      }
      isInterstitialAdLoading = true;
      print("MyLog INTERSTITIAL AD LOADING");
      InterstitialAd.load(
        adUnitId: adId ?? androidInterstitialId,
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print("MyLog INTERSTITIAL AD LOADED");
            adLoadedCount++;
            isInterstitialAdLoading = false;
            _interstitialAd = ad;
            _interstitialAd!.setImmersiveMode(true);
            if (functionToTrigger != null) {
              showInterstitialAd(
                  navigatorKey.currentContext!, functionToTrigger);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) print('INTERSTITIAL AD failed to load: $error.');
            _interstitialAd = null;
            isInterstitialAdLoading = false;
            if (functionToTrigger != null) {
              showInterstitialAd(
                  navigatorKey.currentContext!, functionToTrigger);
            } else {
              // Preload retry — keep trying to have one ready app-wide.
              Timer(const Duration(seconds: 15), () => loadInterstitialAd(null));
            }
          },
        ),
      );
    } else {
      isInterstitialAdLoading = false;
      if (functionToTrigger != null) functionToTrigger();
    }
  }

  Future<void> loadAndShowInterstitialAd(
    Function functionToTrigger, {
    int adShowValue = 1,
    bool? showAdWithoutCounterCheck,
    String? adId,
  }) async {
    print("MYLOG = loadAndShowInterstitialAd called");
    if (adsShownCounter > ads_show_counter_limit) {
      functionToTrigger();
      return;
    }
    if (adShowValue == 0) {
      functionToTrigger();
      return;
    }
    if (SHOW_ADS) {
      int lastAdShownTimeInSeconds =
          DateTime.now().difference(lastInterstitialAdShownDateTime).inSeconds;

      if (showAdWithoutCounterCheck == null) {
        userInteractionCounter++;
      } else {
        userInteractionCounter = 100;
        lastAdShownTimeInSeconds = 999999;
      }

      if (userInteractionCounter >= userInteractionCounterLimit &&
          lastAdShownTimeInSeconds > interstital_timer_in_seconds) {
        if (!isInterstitialAdLoading && adLoadedCount < adLoadedLimit) {
          if (_interstitialAd == null) {
            loadInterstitialAd(functionToTrigger, adId: adId);
          } else {
            // Timer(
            //   Duration(seconds: interstital_ad_loading_screen_time_in_sec),
            //   () async {
                isInterstitialAdLoading = false;
                showInterstitialAd(
                    navigatorKey.currentContext!, functionToTrigger);
            //   },
            // );
          }
        } else {
          functionToTrigger();
        }
      } else {
        if (userInteractionCounter >= userInteractionCounterLimit - 1) {
          loadInterstitialAd(null);
        }
        functionToTrigger();
      }
    } else {
      functionToTrigger();
    }
  }

  void showInterstitialAd(BuildContext ctx, Function functionToTrigger) {
    if (!SHOW_ADS) {
      functionToTrigger();
      return;
    }
    if (_interstitialAd == null) {
      functionToTrigger();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdClicked: (Ad ad) {
        adsClickedCounter++;
        if (adsClickedCounter > ads_clicked_counter_limit) {
          adsShownCounter = 1000000;
        }
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) async {
        _interstitialAd = null;
        ad.dispose();
        userInteractionCounter = 0;
        functionToTrigger();
        lastInterstitialAdShownDateTime = DateTime.now();
        // Keep an interstitial preloaded at all times (requirement: pre-load
        // interstitial ad for entire app).
        loadInterstitialAd(null);
        await Future.delayed(const Duration(seconds: 1));
        AppOpenAdManager.showAppOpenAd = true;
      },
      onAdFailedToShowFullScreenContent:
          (InterstitialAd ad, AdError error) async {
        _interstitialAd = null;
        if (kDebugMode) print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        functionToTrigger();
        loadInterstitialAd(null);
        await Future.delayed(const Duration(seconds: 1));
        AppOpenAdManager.showAppOpenAd = true;
      },
    );
    AppOpenAdManager.showAppOpenAd = false;
    _interstitialAd!.show();
    adsShownCounter++;
  }

  // ── Rewarded ───────────────────────────────────────────────────────────────
  static const String _buttonClickedKey = 'rewarded_button_clicked_count';

  Future<int> _getButtonClickedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_buttonClickedKey) ?? 0;
  }

  Future<void> _setButtonClickedCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_buttonClickedKey, count);
  }

  Future<void> loadAndShowRewardedAd(Function functionToTrigger) async {
    if (SHOW_ADS) {
      if (adsShownCounter > ads_show_counter_limit) {
        functionToTrigger();
        return;
      }
      int buttonClicked = await _getButtonClickedCount();
      buttonClicked++;
      await _setButtonClickedCount(buttonClicked);
      if (buttonClicked < 3) {
        if (buttonClicked > 1) loadRewardedAd(null);
        functionToTrigger();
        return;
      }
      await _setButtonClickedCount(0);
      if (rewardedAd == null) {
        loadRewardedAd(functionToTrigger);
      } else {
       // Timer(Duration(seconds: interstital_ad_loading_screen_time_in_sec),
        //    () async {
          showRewardAd(functionToTrigger);
        //});
      }
    } else {
      functionToTrigger();
    }
  }

  void loadRewardedAd(Function? functionToTrigger) {
    if (SHOW_ADS) {
      if (adsShownCounter > ads_show_counter_limit) return;
      if (rewardedAd == null && !isRewardAdLoading) {
        isRewardAdLoading = true;
        RewardedAd.load(
          adUnitId: androidRewardAdId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (rewardedAd) {
              print('REWARDED AD LOADED');
              this.rewardedAd = rewardedAd;
              if (functionToTrigger != null) showRewardAd(functionToTrigger);
              isRewardAdLoading = false;
            },
            onAdFailedToLoad: (error) {
              print('REWARDED AD LOADED Failed: $error');
              if (functionToTrigger != null) functionToTrigger();
              isRewardAdLoading = false;
            },
          ),
        );
      } else {
        if (functionToTrigger != null) functionToTrigger();
      }
    } else {
      if (functionToTrigger != null) functionToTrigger();
    }
  }

  void showRewardAd(Function functionToTrigger) {
    if (!SHOW_ADS) {
      functionToTrigger();
      return;
    }
    if (rewardedAd == null) {
      functionToTrigger();
      return;
    }
    bool rewardReceived = false;
    rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdClicked: (Ad ad) {
        adsClickedCounter++;
        if (adsClickedCounter > ads_clicked_counter_limit)
          adsShownCounter = 1000000;
      },
      onAdDismissedFullScreenContent: (ad) async {
        rewardedAd = null;
        ad.dispose();
        if (rewardReceived) functionToTrigger();
        await Future.delayed(const Duration(seconds: 1));
        AppOpenAdManager.showAppOpenAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) async {
        rewardReceived = true;
        ad.dispose();
        functionToTrigger();
        await Future.delayed(const Duration(seconds: 1));
        AppOpenAdManager.showAppOpenAd = true;
      },
    );
    AppOpenAdManager.showAppOpenAd = false;
    rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardReceived = true;
        print('User earned reward of ${reward.amount} type ${reward.type}');
      },
    );
    adsShownCounter++;
  }

  // ── Custom native ad (Android: uses custom XML layout via factory) ─────────
  Widget getCustomNativeAdWidget(BuildContext ctx, double width) {
    if (!SHOW_ADS) return const SizedBox();

    // If a preloaded home-screen native ad is ready, show it instantly instead
    // of waiting on a fresh load.
    if (_preloadedHomeNativeAd != null) {
      final ad = _preloadedHomeNativeAd!;
      _preloadedHomeNativeAd = null;
      // Preload the next one in the background for next time this screen shows.
      preloadHomeScreenNativeAd(ctx);
      return Container(
        width: width,
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
          color: Colors.transparent,
        ),
        child: AdWidget(ad: ad),
      );
    }

    return FutureBuilder<NativeAd?>(
      future:
          _loadCustomNativeAd(ctx, AdsProvider.getProvider().androidNativeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
              color: Colors.transparent,
            ),
            child: const Center(
              child: Text(
                "Fetching ad content...",
                style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          );
        }
        if (snapshot.data == null) return const SizedBox();
        return Container(
          width: width,
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
            color: Colors.transparent,
          ),
          child: AdWidget(ad: snapshot.data!),
        );
      },
    );
  }

  Future<NativeAd?> _loadCustomNativeAd(BuildContext context, String id) async {
    final completer = Completer<NativeAd?>();
    NativeAd nativeAd = NativeAd.fromAdManagerRequest(
      adUnitId: id,
      factoryId: ThemeProvider.getProvider().isDark ? 'customNativeAdLightText':'customNativeAd',
      adManagerRequest: AdManagerAdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => completer.complete(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          print("MyLog Custom Native Ad failed: $error");
          ad.dispose();
          completer.complete(null);
        },
        onAdClicked: (Ad ad) {
          adsClickedCounter++;
          if (adsClickedCounter > ads_clicked_counter_limit)
            adsShownCounter = 1000000;
        },
        onPaidEvent: (Ad ad, double valueMicros, PrecisionType precision,
            String currencyCode) {},
      ),
    );
    nativeAd.load();
    return completer.future;
  }

  // ── Small native (iOS / template fallback) ────────────────────────────────
  Widget getSmallNativeAdWidget(BuildContext ctx, double width,
      bool adHorizontalPadding, bool adBottomPadding) {
    if (!SHOW_ADS) return const SizedBox();
    return FutureBuilder<NativeAd?>(
      future: _loadNativeAd(
          ctx, AdsProvider.getProvider().androidNativeId, TemplateType.small),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              color: Colors.transparent,
            ),
            child: const Center(
              child: Text("Fetching ad content…",
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
          );
        }
        if (snapshot.data == null) return const SizedBox();
        return Container(
          height: 120,
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            color: Colors.transparent,
          ),
          child: Center(child: AdWidget(ad: snapshot.data!)),
        );
      },
    );
  }

  Widget getMediumNativeAdWidget(BuildContext ctx, double width,
      bool adHorizontalPadding, bool adBottomPadding) {
    if (!SHOW_ADS) return const SizedBox();
    return FutureBuilder<NativeAd?>(
      future: _loadNativeAd(
          ctx, AdsProvider.getProvider().androidNativeId, TemplateType.medium),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 355,
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              color: Colors.transparent,
            ),
            child: const Center(
              child: Text("Fetching ad content…",
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
          );
        }
        if (snapshot.data == null) return const SizedBox();
        return Container(
          height: 355,
          width: width,
          margin: EdgeInsetsDirectional.only(
            bottom: adBottomPadding ? 16 : 0,
            start: 6,
            end: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            color: Colors.transparent,
          ),
          child: AdWidget(ad: snapshot.data!),
        );
      },
    );
  }

  Future<NativeAd?> _loadNativeAd(
      BuildContext context, String id, TemplateType templateType) async {
    final completer = Completer<NativeAd?>();
    NativeAd nativeAd = NativeAd(
      adUnitId: id,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        shouldRequestMultipleImages: true,
        mediaAspectRatio: MediaAspectRatio.landscape,
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: templateType,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(size: 16.0),
        primaryTextStyle: NativeTemplateTextStyle(textColor: Colors.black87),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: Colors.black54),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: Colors.black45),
      ),
      listener: NativeAdListener(
        onAdClicked: (Ad ad) {
          adsClickedCounter++;
          if (adsClickedCounter > ads_clicked_counter_limit)
            adsShownCounter = 1000000;
        },
        onAdLoaded: (ad) => completer.complete(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          print("MyLog Native Ad failed to load: $error");
          ad.dispose();
          completer.complete(null);
        },
      ),
    );
    nativeAd.load();
    return completer.future;
  }

  // ── Banner ads ─────────────────────────────────────────────────────────────
  Widget getFullBannerAd(BuildContext ctx, double width) {
    if (!SHOW_ADS) return const SizedBox();
    return FutureBuilder<BannerAd?>(
      future: _loadBannerAd(
          ctx, AdsProvider.getProvider().androidBannerId, AdSize.fullBanner),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 70,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              color: Colors.white,
            ),
            child: const Center(
                child: Text("Fetching ad content…",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12))),
          );
        }
        if (snapshot.data == null) return const SizedBox();
        final bannerAd = snapshot.data!;
        var height = bannerAd.size.height.toDouble();
        if (height < 0) height = 70;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            color: Colors.white,
          ),
          child: AdWidget(ad: bannerAd),
        );
      },
    );
  }

  Widget getLargeBannerAd(BuildContext ctx, double width) {
    if (!SHOW_ADS) return const SizedBox();
    return FutureBuilder<BannerAd?>(
      future: _loadBannerAd(
          ctx, AdsProvider.getProvider().androidBannerId, AdSize.largeBanner),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              color: Colors.white,
            ),
            child: const Center(
                child: Text("Fetching ad content…",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12))),
          );
        }
        if (snapshot.data == null) return const SizedBox();
        final bannerAd = snapshot.data!;
        var height = bannerAd.size.height.toDouble();
        if (height < 0) height = 100;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            color: Colors.white,
          ),
          child: AdWidget(ad: bannerAd),
        );
      },
    );
  }

  Future<BannerAd?> _loadBannerAd(
      BuildContext context, String id, AdSize adSize) async {
    final completer = Completer<BannerAd?>();
    BannerAd bannerAd = BannerAd(
      adUnitId: id,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdClicked: (Ad ad) {
          adsClickedCounter++;
          if (adsClickedCounter > ads_clicked_counter_limit)
            adsShownCounter = 1000000;
        },
        onAdLoaded: (ad) => completer.complete(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          print("MyLog banner Ad failed to load: $error");
          ad.dispose();
          completer.complete(null);
        },
      ),
    );
    bannerAd.load();
    return completer.future;
  }

  // ── Collapsible banner ─────────────────────────────────────────────────────
  Widget getCollapsibleBannerAdWidget(String position, double width) {
    return CollapsibleBannerAdWidget(
        position, width, androidBannerIdCollapsable);
  }

  // ── Remote Config ──────────────────────────────────────────────────────────
  getShowAdsFromRemoteConfig() {
    if (remoteConfig != null) {
      SHOW_ADS = remoteConfig!.getBool("SHOW_ADS");
      show_remote_paywall = remoteConfig!.getBool("show_remote_paywall");
    }
    print("MyLog SHOW_ADS getShowAdsFromRemoteConfig = $SHOW_ADS");
  }

  /// Fetches Remote Config in the background for the values that are still
  /// remote-driven: chabbi (OpenAI key), credit amounts, SHOW_ADS and
  /// show_remote_paywall. This is called WITHOUT `await` from initialize(),
  /// so ad unit IDs / ad placement (parsed locally) and ad loading are never
  /// blocked or delayed by this network call.
  Future<void> _fetchRemoteConfigInBackground(BuildContext ctx,
      {bool? showTestAds}) async {
    log("Fetching Remote Config in background (chabbi/credits/SHOW_ADS only)");
    try {
      remoteConfig = await setupRemoteConfig();
      if (remoteConfig == null) {
        print(
            "MyLog remote config was null — loading cached chabbi/credits/SHOW_ADS");
        await _loadCachedChabbiAndCredits();
        notifyListeners();
        return;
      }

      getShowAdsFromRemoteConfig();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kShowAds, SHOW_ADS);

      // ── OpenAI key (chabbi) ────────────────────────────────────────────
      final chabbi = remoteConfig!.getString('chabbi');
      if (chabbi.isNotEmpty) {
        await prefs.setString(_kChabbi, chabbi);
        print("MyLog chabbi fetched and cached from Remote Config");
      }

      // ── Credits per subscription cycle ──────────────────────────────────
      final weeklyCredits = remoteConfig!.getInt('weekly_credits_per_cycle');
      final monthlyCredits = remoteConfig!.getInt('monthly_credits_per_cycle');
      final yearlyCredits = remoteConfig!.getInt('yearly_credits_per_cycle');
      if (weeklyCredits > 0) {
        await prefs.setInt(_kWeeklyCredits, weeklyCredits);
      }
      if (monthlyCredits > 0) {
        await prefs.setInt(_kMonthlyCredits, monthlyCredits);
      }
      if (yearlyCredits > 0) {
        await prefs.setInt(_kYearlyCredits, yearlyCredits);
      }
      print(
          "MyLog Remote Config (background) applied: SHOW_ADS=$SHOW_ADS show_remote_paywall=$show_remote_paywall w=$weeklyCredits m=$monthlyCredits y=$yearlyCredits");
      notifyListeners();
    } catch (e) {
      print("MyLog Remote Config background fetch ERROR = $e");
      await _loadCachedChabbiAndCredits();
      notifyListeners();
    }
  }

  /// Loads the last-known SHOW_ADS flag from SharedPreferences so the app
  /// works fully offline. chabbi/credits already fall back to
  /// RemoteConfigService's own cached-value + AppConstants defaults.
  Future<void> _loadCachedChabbiAndCredits() async {
    final prefs = await SharedPreferences.getInstance();
    SHOW_ADS = prefs.getBool(_kShowAds) ?? SHOW_ADS;
    print("MyLog Loaded cached SHOW_ADS from SharedPreferences (offline)");
  }

  Future<FirebaseRemoteConfig> setupRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(seconds: 30),
      ),
    );
    try {
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      print("MyLog Remote Config fetch failed: $e");
    }
    return remoteConfig;
  }

  // ── Main ad widget dispatcher ─────────────────────────────────────────────
  Widget getAdWidget(int type) {
    final context = navigatorKey.currentContext!;
    final double width =
        MediaQuery.of(context).size.width.truncate().toDouble();
    if (type == FULL_BANNER_AD) {
      return getFullBannerAd(context, width);
    } else if (type == LARGE_BANNER_AD) {
      return getLargeBannerAd(context, width);
    } else if (type == COLLAPSABLE_BANNER_AD_TOP) {
      return CollapsibleBannerAdWidget(
          "top", width, androidBannerIdCollapsable);
    } else if (type == COLLAPSABLE_BANNER_AD_BOTTOM) {
      return CollapsibleBannerAdWidget(
          "bottom", width, androidBannerIdCollapsable);
    } else if (type == SMALL_NATIVE_AD) {
      if (Platform.isAndroid) {
        return getCustomNativeAdWidget(context, width);
      }
      return getSmallNativeAdWidget(context, width, false, false);
    } else if (type == MEDIUM_NATIVE_AD) {
      return getMediumNativeAdWidget(context, width, false, false);
    } else {
      print("MyLog SizedBox returned in getAdWidget (NO_AD type=$type)");
      return const SizedBox();
    }
  }

  static AdsProvider getProvider() {
    return Provider.of<AdsProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
  }
}

// ─── CollapsibleBannerAdWidget ────────────────────────────────────────────────
class CollapsibleBannerAdWidget extends StatefulWidget {
  final String? bannerType;
  final double width;
  final String adId;

  const CollapsibleBannerAdWidget(this.bannerType, this.width, this.adId,
      {super.key});

  @override
  State<CollapsibleBannerAdWidget> createState() =>
      _CollapsibleBannerAdWidgetState();
}

class _CollapsibleBannerAdWidgetState extends State<CollapsibleBannerAdWidget> {
  bool isCollapsibleBannerAdFailed = false;
  bool isCollapsibleBannerAdLoaded = false;
  BannerAd? _bannerAd;

  Future<void> _setCollapsibleBannerAd() async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      widget.width.truncate(),
    );
    if (size == null) return;

    AdRequest adRequest = widget.bannerType != null
        ? AdRequest(extras: {"collapsible": widget.bannerType!})
        : const AdRequest();

    _bannerAd = BannerAd(
      adUnitId: widget.adId,
      request: adRequest,
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => isCollapsibleBannerAdLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          if (mounted) setState(() => isCollapsibleBannerAdFailed = true);
          _bannerAd = null;
          ad.dispose();
        },
        onAdClicked: (Ad ad) {
          AdsProvider.getProvider().adsClickedCounter++;
          if (AdsProvider.getProvider().adsClickedCounter >
              AdsProvider.getProvider().ads_clicked_counter_limit) {
            AdsProvider.getProvider().adsShownCounter = 1000000;
          }
        },
      ),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    if (AdsProvider.SHOW_ADS) {
      _setCollapsibleBannerAd();
    } else {
      setState(() => isCollapsibleBannerAdFailed = true);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && isCollapsibleBannerAdLoaded) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        color: Colors.transparent,
        child: AdWidget(ad: _bannerAd!),
      );
    }
    if (isCollapsibleBannerAdFailed) return const SizedBox();
    return Container(
      height: 70,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        color: Colors.white,
      ),
      child: const Center(
        child: Text("Fetching ad content…",
            style: TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── AppOpenAdManager ─────────────────────────────────────────────────────────
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  String id;
  bool appGoneInBackGround = false;
  static bool showAppOpenAd = true;

  AppOpenAdManager(this.id);

  void loadAndShowApOpenAd(Function? functionToCall, {String? adID}) {
    if (!AdsProvider.SHOW_ADS) {
      if (functionToCall != null) functionToCall();
      return;
    }
    if (!showAppOpenAd || !appGoneInBackGround) return;

    if (_appOpenAd == null) {
      loadApOpenAd(functionToCall, adId: adID, showAdAfterLoading: true);
    } else {
      //Timer(const Duration(seconds: 2), () async {
        showAppOpenAdIfAvailable(functionToCall);
     // });
    }
  }

  void loadApOpenAd(Function? functionToCall,
      {String? adId, bool showAdAfterLoading = false}) {
    if (!AdsProvider.SHOW_ADS) {
      if (functionToCall != null) functionToCall();
      return;
    }
    if (_appOpenAd == null) {
      AppOpenAd.load(
        adUnitId: adId ?? id,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            print("MyLog _appOpenAd loaded");
            _appOpenAd = ad;
            if (showAdAfterLoading) showAppOpenAdIfAvailable(functionToCall);
          },
          onAdFailedToLoad: (error) {
            print("MyLog _appOpenAd error : $error");
            appGoneInBackGround = false;
            _appOpenAd = null;
            if (showAdAfterLoading && functionToCall != null) functionToCall();
          },
        ),
      );
    }
  }

  void showAppOpenAdIfAvailable(Function? functionToCall) {
    if (_appOpenAd == null) return;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        if (functionToCall != null) functionToCall();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _appOpenAd = null;
        ad.dispose();
        if (functionToCall != null) functionToCall();
      },
    );
    try {
      if (appGoneInBackGround) {
        _appOpenAd!.show();
        appGoneInBackGround = false;
      }
    } catch (e) {
      print("MyLog AppOpenAd show ERROR: $e");
    }
  }
}

// ─── ConsentManager ───────────────────────────────────────────────────────────
class ConsentManager {
  static Future<void> gatherConsent({
    String? testDeviceHashedId,
    bool forceTestEEA = false,
  }) async {
    final params = ConsentRequestParameters();
    if (testDeviceHashedId != null) {
      params.consentDebugSettings = ConsentDebugSettings(
        debugGeography: forceTestEEA
            ? DebugGeography.debugGeographyEea
            : DebugGeography.debugGeographyDisabled,
        testIdentifiers: [testDeviceHashedId],
      );
    }
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          final formCompleter = Completer<void>();
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) {
            if (formError != null) {
              debugPrint(
                  'Form error: ${formError.errorCode} - ${formError.message}');
            }
            formCompleter.complete();
          });
          await formCompleter.future;
        }
        completer.complete();
      },
      (FormError error) {
        debugPrint('UMP consent error: ${error.errorCode} - ${error.message}');
        completer.complete();
      },
    );
    return completer.future;
  }

  static Future<bool> canRequestAds() async {
    return await ConsentInformation.instance.canRequestAds();
  }

  static Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? formError) {
      if (formError != null) {
        debugPrint(
            'Privacy form error: ${formError.errorCode} - ${formError.message}');
      }
      completer.complete();
    });
    return completer.future;
  }

  static Future<void> resetConsent() async {
    await ConsentInformation.instance.reset();
  }
}

// ─── AppLifecycleReactor ──────────────────────────────────────────────────────
class AppLifecycleReactor extends StatefulWidget {
  final Widget child;

  const AppLifecycleReactor({required this.child, super.key});

  @override
  State<AppLifecycleReactor> createState() => _AppLifecycleReactorState();
}

class _AppLifecycleReactorState extends State<AppLifecycleReactor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (AdsProvider.SHOW_ADS) {
        AdsProvider.getProvider().appOpenAdManager?.loadAndShowApOpenAd(null);
      } else {
        AdsProvider.getProvider().appOpenAdManager?.appGoneInBackGround = false;
      }
    } else if (state == AppLifecycleState.hidden) {
      AdsProvider.getProvider().appOpenAdManager?.appGoneInBackGround = true;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
