import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/price_alert.dart';
import '../../../services/alerts_service.dart';
import '../../../widgets/shared_widgets.dart';
import '../../providers.dart';
import '../../../services/ad_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AlertsService.instance.requestPermission();
      if (mounted) context.read<AlertsProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertsProv = context.watch<AlertsProvider>();
    final isPro = context.watch<SubscriptionProvider>().isPro;
    final bgColor = AppTheme.bgColor(context);
    final borderColor = AppTheme.borderColor(context);
    final gold = AppTheme.gold(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppTopBar(
        title: 'Price Alerts',
        actions: [
          if (alertsProv.lastChecked != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => context.read<AlertsProvider>().checkAlerts(),
                child: Icon(Icons.refresh_rounded,
                    color: AppTheme.textSecondary(context), size: 20),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: Insets.md, vertical: Insets.sm),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: borderColor),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                    colors: [gold, gold.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(60),
              ),
              labelColor: AppTheme.bgColor(context),
              unselectedLabelColor: AppTheme.textSecondary(context),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: '    Active (${alertsProv.activeCount})    '),
                Tab(text: '    Triggered (${alertsProv.triggeredAlerts.length}    '),
              ],
            ),
          ),

          // Ad banner for free users
          if (!isPro) const _AlertsBannerAd(),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ActiveAlertsTab(alertsProv: alertsProv),
                _TriggeredAlertsTab(alertsProv: alertsProv),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlertSheet(context),
        backgroundColor: gold,
        foregroundColor: AppTheme.bgColor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Alert', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddAlertSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (_) => const _AddAlertSheet(),
    );
  }
}

// ── Active Alerts Tab ─────────────────────────────────────────────────────────

class _ActiveAlertsTab extends StatelessWidget {
  final AlertsProvider alertsProv;
  const _ActiveAlertsTab({required this.alertsProv});

  @override
  Widget build(BuildContext context) {
    if (alertsProv.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(Insets.md),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: Insets.sm),
        itemBuilder: (_, __) => const ShimmerBlock(height: 72, borderRadius: Radii.lg),
      );
    }

    if (alertsProv.activeAlerts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.notifications_none_rounded,
        title: 'No Active Alerts',
        subtitle: 'Tap "New Alert" to get notified when a pair hits your target price.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Insets.md),
      itemCount: alertsProv.activeAlerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: Insets.sm),
      itemBuilder: (ctx, i) => _AlertTile(
        alert: alertsProv.activeAlerts[i],
        isActive: true,
      ),
    );
  }
}

// ── Triggered Alerts Tab ──────────────────────────────────────────────────────

class _TriggeredAlertsTab extends StatelessWidget {
  final AlertsProvider alertsProv;
  const _TriggeredAlertsTab({required this.alertsProv});

  @override
  Widget build(BuildContext context) {
    if (alertsProv.triggeredAlerts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Triggered Alerts',
        subtitle: 'Alerts that have fired will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(Insets.md),
      itemCount: alertsProv.triggeredAlerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: Insets.sm),
      itemBuilder: (ctx, i) => _AlertTile(
        alert: alertsProv.triggeredAlerts[i],
        isActive: false,
      ),
    );
  }
}

// ── Alert Tile ────────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  final PriceAlert alert;
  final bool isActive;
  const _AlertTile({required this.alert, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final gold     = AppTheme.gold(context);
    final emerald  = AppTheme.emerald(context);
    final red      = AppTheme.red(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.borderColor(context);

    final conditionColor = alert.condition == AlertCondition.above ? emerald : red;
    final conditionLabel = alert.condition == AlertCondition.above ? 'Above' : 'Below';
    final conditionIcon  = alert.condition == AlertCondition.above
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Dismissible(
      key: ValueKey(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Insets.md),
        decoration: BoxDecoration(
          color: red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: red),
      ),
      onDismissed: (_) => context.read<AlertsProvider>().deleteAlert(alert.id),
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(
            color: isActive ? borderColor : borderColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: conditionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(conditionIcon, color: conditionColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(alert.pair,
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppTheme.textPrimary(context)
                                : AppTheme.textMuted(context),
                          )),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: conditionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Radii.full),
                        ),
                        child: Text(conditionLabel,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: conditionColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${alert.targetPrice.toStringAsFixed(alert.targetPrice >= 1 ? 2 : 6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? AppTheme.textSecondary(context) : AppTheme.textMuted(context),
                    ),
                  ),
                  if (!isActive && alert.triggeredAt != null)
                    Text(
                      'Triggered ${_formatDate(alert.triggeredAt!)}',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context)),
                    ),
                ],
              ),
            ),
            if (isActive)
              GestureDetector(
                onTap: () => context.read<AlertsProvider>().toggleAlert(alert.id),
                child: Container(
                  width: 36, height: 20,
                  decoration: BoxDecoration(
                    color: alert.isActive ? gold : AppTheme.neutral(context),
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    alignment: alert.isActive ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 16, height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Add Alert Bottom Sheet ────────────────────────────────────────────────────

class _AddAlertSheet extends StatefulWidget {
  const _AddAlertSheet();

  @override
  State<_AddAlertSheet> createState() => _AddAlertSheetState();
}

class _AddAlertSheetState extends State<_AddAlertSheet> {
  String _selectedPair = AppConstants.cryptoPairs.first;
  AlertCondition _condition = AlertCondition.above;
  final _priceCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = AppTheme.gold(context);
    final bgColor = AppTheme.bgColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.borderColor(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Padding(
      padding: EdgeInsets.only(
        left: Insets.md, right: Insets.md, top: Insets.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Insets.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Insets.md),
          Text('Create Price Alert',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: Insets.lg),

          // Pair picker
          Text('Pair', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPair,
                isExpanded: true,
                dropdownColor: cardColor,
                style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600),
                items: AppConstants.cryptoPairs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPair = v!),
              ),
            ),
          ),
          const SizedBox(height: Insets.md),

          // Condition
          Text('Condition', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ConditionBtn(
                  label: 'Price Goes Above',
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.emerald(context),
                  isSelected: _condition == AlertCondition.above,
                  onTap: () => setState(() => _condition = AlertCondition.above),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ConditionBtn(
                  label: 'Price Falls Below',
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.red(context),
                  isSelected: _condition == AlertCondition.below,
                  onTap: () => setState(() => _condition = AlertCondition.below),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),

          // Target price
          Text('Target Price (USD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 16, color: textPrimary, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'e.g. 65000',
              hintStyle: TextStyle(color: AppTheme.textMuted(context), fontWeight: FontWeight.w400),
              prefixText: '\$ ',
              prefixStyle: TextStyle(color: gold, fontWeight: FontWeight.w700),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: gold, width: 1.5),
              ),
              errorText: _error,
            ),
          ),
          const SizedBox(height: Insets.lg),

          // Submit
          GradientButton(
            label: _isSubmitting ? 'Creating...' : 'Create Alert',
            onTap: _isSubmitting ? null : _submit,
            height: 50,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final priceStr = _priceCtrl.text.trim();
    final price = double.tryParse(priceStr);
    if (price == null || price <= 0) {
      setState(() => _error = 'Please enter a valid price');
      return;
    }
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await context.read<AlertsProvider>().addAlert(
        pair: _selectedPair,
        targetPrice: price,
        condition: _condition,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = 'Failed to create alert'; _isSubmitting = false; });
    }
  }
}

class _ConditionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionBtn({
    required this.label, required this.icon, required this.color,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : AppTheme.borderColor(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textMuted(context), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isSelected ? color : AppTheme.textSecondary(context),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner Ad Widget (for free users) ────────────────────────────────────────

class _AlertsBannerAd extends StatelessWidget {
  const _AlertsBannerAd();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgColor(context),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const AdBannerWidget(),
    );
  }
}
