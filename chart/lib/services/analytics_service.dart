import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:purchases_flutter/purchases_flutter.dart';

/// Reports real-money purchases to Firebase Analytics so they can be imported
/// into Google Ads as conversions with value (required for tROAS bidding).
///
/// Every call is fire-and-forget and fully guarded: analytics can never throw
/// into, delay, or alter the purchase / credit-granting flow.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  /// Logs a standard GA4 `purchase` event (value + currency) for a completed
  /// store purchase. Used for both subscriptions and consumable credit packs.
  ///
  /// [transactionId] lets Analytics de-duplicate the same purchase.
  Future<void> logPurchase({
    required StoreProduct product,
    required String itemCategory,
    String? transactionId,
  }) async {
    try {
      // Revenue actually charged now. If the user got an introductory offer,
      // use that price; a free trial (0) has no revenue yet, so no purchase
      // event is sent (otherwise tROAS would count revenue never collected).
      final intro = product.introductoryPrice;
      final double value = intro != null ? intro.price : product.price;
      final String currency = product.currencyCode;

      if (value <= 0 || currency.isEmpty) return;

      await FirebaseAnalytics.instance.logPurchase(
        currency: currency,
        value: value,
        transactionId: transactionId,
        items: [
          AnalyticsEventItem(
            itemId: product.identifier,
            itemName: product.title,
            itemCategory: itemCategory,
            price: value,
            quantity: 1,
          ),
        ],
      );
    } catch (e) {
      debugPrint('MyLog Analytics purchase log failed: $e');
    }
  }
}
