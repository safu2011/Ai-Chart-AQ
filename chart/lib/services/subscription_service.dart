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

  // ── Init ──────────────────────────────────────────────────────────────────

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

  // ── Pro Status ────────────────────────────────────────────────────────────

  /// Returns true when the user has any active subscription under the
  /// "pro" entitlement.
  Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(AppConstants.rcProEntitlement);
    } catch (_) {
      return false;
    }
  }

  // ── Subscription Tier ─────────────────────────────────────────────────────

  /// Determines which subscription tier is currently active by inspecting
  /// active subscriptions on the CustomerInfo object.
  Future<SubscriptionTier> getActiveSubscriptionTier() async {
    try {
      final info = await Purchases.getCustomerInfo();

      if (!info.entitlements.active.containsKey(AppConstants.rcProEntitlement)) {
        return SubscriptionTier.none;
      }

      // Check active subscriptions for the product identifier
      final activeSubscriptions = info.activeSubscriptions;

      for (final productId in activeSubscriptions) {
        if (productId == AppConstants.rcYearlySubId ||
            productId.contains('yearly')) {
          return SubscriptionTier.yearly;
        }
        if (productId == AppConstants.rcMonthlySubId ||
            productId.contains('monthly')) {
          return SubscriptionTier.monthly;
        }
        if (productId == AppConstants.rcWeeklySubId ||
            productId.contains('weekly')) {
          return SubscriptionTier.weekly;
        }
      }

      // Fallback: entitlement is active but tier unrecognised → treat as monthly
      return SubscriptionTier.monthly;
    } catch (_) {
      return SubscriptionTier.none;
    }
  }

  // ── Offerings ─────────────────────────────────────────────────────────────

  /// Fetches offerings from RevenueCat. Returns the "pro" offering if
  /// available, otherwise falls back to current.
  Future<Offerings?> fetchOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  /// Purchases a [package]. Returns updated [CustomerInfo] on success.
  Future<CustomerInfo> purchase(Package package) async {
    return Purchases.purchasePackage(package);
  }

  /// Restores previous purchases.
  Future<CustomerInfo> restore() async {
    return Purchases.restorePurchases();
  }

  // ── Customer Info ─────────────────────────────────────────────────────────

  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }
}