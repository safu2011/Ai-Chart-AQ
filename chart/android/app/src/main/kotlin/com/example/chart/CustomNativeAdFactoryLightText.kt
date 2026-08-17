package com.example.chart

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class CustomNativeAdFactoryLightText(private val layoutInflater: LayoutInflater) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.native_ad_custom_light_text,
            null
        ) as NativeAdView

        // Headline
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        // Body
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body != null) {
            bodyView.visibility = View.VISIBLE
            bodyView.text = nativeAd.body
        } else {
            bodyView.visibility = View.GONE
        }
        adView.bodyView = bodyView

        // Advertiser
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        if (nativeAd.advertiser != null) {
            advertiserView.visibility = View.VISIBLE
            advertiserView.text = nativeAd.advertiser
        } else {
            advertiserView.visibility = View.GONE
        }
        adView.advertiserView = advertiserView

        // Icon / Image
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val icon = nativeAd.icon
        if (icon != null) {
            iconView.setImageDrawable(icon.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            val images = nativeAd.images
            if (images.isNotEmpty()) {
                iconView.setImageDrawable(images[0].drawable)
                iconView.visibility = View.VISIBLE
            } else {
                iconView.visibility = View.GONE
            }
        }
        adView.iconView = iconView

        // CTA Button
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)
        if (nativeAd.callToAction != null) {
            ctaView.visibility = View.VISIBLE
            ctaView.text = nativeAd.callToAction
        } else {
            ctaView.visibility = View.GONE
        }
        adView.callToActionView = ctaView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
