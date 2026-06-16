import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants/app_constants.dart';

/// Subscription tier derived from active entitlement + product identifier.
enum SubscriptionTier {
  none,    // No active subscription
  weekly,  // weekly:weekly
  monthly, // monthly:monthly
  yearly,  // yearly:yearly
}

/// Wraps RevenueCat SDK — all IAP and subscription logic lives here.
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Purchases.setLogLevel(LogLevel.warn);
    final config = PurchasesConfiguration(
      Platform.isAndroid
          ? AppConstants.revenueCatApiKeyAndroid
          : AppConstants.revenueCatApiKeyIos,
    );
    await Purchases.configure(config);
    _initialized = true;
  }

  Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(AppConstants.rcProEntitlement);
    } catch (_) {
      return false;
    }
  }

  Future<SubscriptionTier> getActiveSubscriptionTier() async {
    try {
      final info = await Purchases.getCustomerInfo();
      if (!info.entitlements.active.containsKey(AppConstants.rcProEntitlement)) {
        return SubscriptionTier.none;
      }
      final activeSubscriptions = info.activeSubscriptions;
      for (final productId in activeSubscriptions) {
        if (productId == AppConstants.rcYearlySubId || productId.contains('yearly')) {
          return SubscriptionTier.yearly;
        }
        if (productId == AppConstants.rcMonthlySubId || productId.contains('monthly')) {
          return SubscriptionTier.monthly;
        }
        if (productId == AppConstants.rcWeeklySubId || productId.contains('weekly')) {
          return SubscriptionTier.weekly;
        }
      }
      return SubscriptionTier.monthly;
    } catch (_) {
      return SubscriptionTier.none;
    }
  }

  /// Returns credits allotted per cycle for a given tier.
  int creditsForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.weekly:  return AppConstants.weeklyCreditsPerCycle;
      case SubscriptionTier.monthly: return AppConstants.monthlyCreditsPerCycle;
      case SubscriptionTier.yearly:  return AppConstants.yearlyCreditsPerCycle;
      case SubscriptionTier.none:    return 0;
    }
  }

  /// The renewal/expiration timestamp RevenueCat reports for the active
  /// "pro" entitlement. Used as the anchor to detect a new billing cycle.
  Future<DateTime?> getEntitlementExpirationDate(CustomerInfo info) async {
    final ent = info.entitlements.active[AppConstants.rcProEntitlement];
    if (ent == null) return null;
    final raw = ent.expirationDate; // ISO8601 string from RC
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<Offerings?> fetchOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  Future<CustomerInfo> purchase(Package package) async {
    return Purchases.purchasePackage(package);
  }

  Future<CustomerInfo> restore() async {
    return Purchases.restorePurchases();
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }
}