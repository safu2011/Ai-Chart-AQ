import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/price_alert.dart';
import 'binance_service.dart';

/// Manages price alerts and local notifications.
///
/// Alerts are persisted in SharedPreferences as JSON.
/// A background poll is triggered by [checkAlerts] — call this periodically
/// (e.g. from a timer or WorkManager in a real app).
class AlertsService {
  static final AlertsService instance = AlertsService._();
  AlertsService._();

  static const _kAlertsKey = 'price_alerts';

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _notifInitialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_notifInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _notifInitialized = true;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<PriceAlert>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kAlertsKey) ?? [];
    return raw
        .map((s) => PriceAlert.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(PriceAlert alert) async {
    final alerts = await loadAll();
    alerts.add(alert);
    await _save(alerts);
  }

  Future<void> delete(String id) async {
    final alerts = await loadAll();
    await _save(alerts.where((a) => a.id != id).toList());
  }

  Future<void> toggle(String id) async {
    final alerts = await loadAll();
    final idx = alerts.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    alerts[idx] = alerts[idx].copyWith(isActive: !alerts[idx].isActive);
    await _save(alerts);
  }

  Future<void> markTriggered(String id) async {
    final alerts = await loadAll();
    final idx = alerts.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    alerts[idx] = alerts[idx].copyWith(
      isActive: false,
      triggeredAt: DateTime.now(),
    );
    await _save(alerts);
  }

  Future<void> _save(List<PriceAlert> alerts) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _kAlertsKey,
      alerts.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  // ── Alert Checking ────────────────────────────────────────────────────────

  /// Check all active alerts against current market prices.
  /// Call this on a timer (every 30–60 seconds when app is in foreground).
  Future<void> checkAlerts() async {
    final alerts = await loadAll();
    final active = alerts.where((a) => a.isActive).toList();
    if (active.isEmpty) return;

    // Group by pair to minimise API calls
    final pairs = active.map((a) => a.pair).toSet();
    final prices = <String, double>{};

    for (final pair in pairs) {
      try {
        final ticker = await BinanceService.instance.getTicker(pair);
        final price = double.tryParse(ticker['lastPrice'] as String? ?? '');
        if (price != null) prices[pair] = price;
      } catch (_) {
        // Silently skip if ticker fetch fails
      }
    }

    for (final alert in active) {
      final currentPrice = prices[alert.pair];
      if (currentPrice == null) continue;

      bool triggered = false;
      if (alert.condition == AlertCondition.above &&
          currentPrice >= alert.targetPrice) {
        triggered = true;
      } else if (alert.condition == AlertCondition.below &&
          currentPrice <= alert.targetPrice) {
        triggered = true;
      }

      if (triggered) {
        await _fireNotification(alert, currentPrice);
        await markTriggered(alert.id);
      }
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> _fireNotification(PriceAlert alert, double currentPrice) async {
    if (!_notifInitialized) return;

    final conditionWord =
        alert.condition == AlertCondition.above ? 'above' : 'below';
    final title = '${alert.pair} Alert Triggered 🔔';
    final body =
        '${alert.pair} is now \$${currentPrice.toStringAsFixed(2)} — '
        '$conditionWord your target of \$${alert.targetPrice.toStringAsFixed(2)}';

    await _notifications.show(
      alert.id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'price_alerts',
          'Price Alerts',
          channelDescription: 'Notifies when your price alert targets are hit',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? true; // Android doesn't need explicit permission < API 33
  }
}
