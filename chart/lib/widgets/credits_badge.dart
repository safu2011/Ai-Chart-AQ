import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/iap/credit_packs_screen.dart';
import '../features/providers.dart';

/// Live remaining-credits badge (lifetime IAP + subscription/free credits).
/// Rebuilds automatically whenever the balance changes. Tapping it opens the
/// one-time credit packs screen.
class CreditsBadge extends StatelessWidget {
  const CreditsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context
        .select<SubscriptionProvider, int>((s) => s.totalCredits);
    final empty = total <= 0;
    final color = empty ? AppTheme.red(context) : AppTheme.gold(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreditPacksScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(Radii.full),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: color, size: 14),
            const SizedBox(width: 3),
            Text(
              '$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
