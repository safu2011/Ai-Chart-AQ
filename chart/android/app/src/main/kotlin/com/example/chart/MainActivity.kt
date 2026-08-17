package com.example.chart

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Register custom native ad factory (matches factoryId: 'customNativeAd' in AdsProvider)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "customNativeAd",
            CustomNativeAdFactory(layoutInflater)
        )

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "customNativeAdLightText",
            CustomNativeAdFactoryLightText(layoutInflater)
        )

        // Method channel to dynamically update AdMob app ID from remote config
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/method_channel")
            .setMethodCallHandler { call, result ->
                if (call.method == "changeApplicationId") {
                    val id: String? = call.argument("id")
                    if (id != null) {
                        val success = updateApplicationId(id)
                        result.success(if (success) "set" else "failed")
                    } else {
                        result.error("INVALID_ARGUMENT", "ID is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "customNativeAd")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "customNativeAdLightText")
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun updateApplicationId(id: String): Boolean {
        return try {
            val packageManager: PackageManager = applicationContext.packageManager
            val applicationInfo: ApplicationInfo = packageManager.getApplicationInfo(
                applicationContext.packageName,
                PackageManager.GET_META_DATA
            )
            applicationInfo.metaData.putString(
                "com.google.android.gms.ads.APPLICATION_ID",
                id
            )
            true
        } catch (e: PackageManager.NameNotFoundException) {
            e.printStackTrace()
            false
        } catch (e: NullPointerException) {
            e.printStackTrace()
            false
        }
    }
}
