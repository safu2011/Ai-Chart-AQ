import 'dart:convert';

enum AlertCondition { above, below }

class PriceAlert {
  final String id;
  final String pair;
  final double targetPrice;
  final AlertCondition condition;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  const PriceAlert({
    required this.id,
    required this.pair,
    required this.targetPrice,
    required this.condition,
    required this.isActive,
    required this.createdAt,
    this.triggeredAt,
  });

  factory PriceAlert.create({
    required String pair,
    required double targetPrice,
    required AlertCondition condition,
  }) {
    return PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pair: pair,
      targetPrice: targetPrice,
      condition: condition,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  PriceAlert copyWith({
    bool? isActive,
    DateTime? triggeredAt,
  }) {
    return PriceAlert(
      id: id,
      pair: pair,
      targetPrice: targetPrice,
      condition: condition,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      pair: json['pair'] as String,
      targetPrice: (json['target_price'] as num).toDouble(),
      condition: json['condition'] == 'above'
          ? AlertCondition.above
          : AlertCondition.below,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pair': pair,
        'target_price': targetPrice,
        'condition': condition == AlertCondition.above ? 'above' : 'below',
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'triggered_at': triggeredAt?.toIso8601String(),
      };
}
