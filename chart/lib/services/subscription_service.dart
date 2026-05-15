import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants/app_constants.dart';

/// Wraps RevenueCat SDK — all IAP and subscription logic lives here.
///
/// Usage:
///   await SubscriptionService.instance.init();
///   final isPro = await SubscriptionService.instance.isPro();
///   final offerings = await SubscriptionService.instance.fetchOfferings();
///   await SubscriptionService.instance.purchase(package);
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

  /// Returns true when the user has an active Pro subscription.
  Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(AppConstants.rcProEntitlement);
    } catch (_) {
      return false;
    }
  }

  // ── Offerings ─────────────────────────────────────────────────────────────

  /// Fetches current offerings from RevenueCat.
  Future<Offerings?> fetchOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  /// Purchases a [package]. Returns updated [CustomerInfo] on success.
  /// Throws [PurchasesErrorCode] on failure.
  Future<CustomerInfo> purchase(Package package) async {
    final result = await Purchases.purchasePackage(package);
    return result;
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
