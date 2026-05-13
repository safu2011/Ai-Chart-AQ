import 'dart:convert';

/// The structured AI analysis result returned by OpenAI Vision
class ChartAnalysis {
  final String id;
  final DateTime timestamp;
  final String assetType; // Crypto / Forex / Stocks
  final String pair; // e.g. BTC/USDT or user description
  final String sentiment; // Bullish | Bearish | Neutral
  final double sentimentScore; // 0.0–1.0
  final double volumeScore; // 0.0–1.0
  final String volumeLabel; // Low | Medium | High
  final String summary;
  final String keyLevels;
  final String tradeScenario;
  final String riskAnalysis;
  final String finalNotes;
  final String rawMarkdown;
  String? chartImagePath;

  ChartAnalysis({
    required this.id,
    required this.timestamp,
    required this.assetType,
    required this.pair,
    required this.sentiment,
    required this.sentimentScore,
    required this.volumeScore,
    required this.volumeLabel,
    required this.summary,
    required this.keyLevels,
    required this.tradeScenario,
    required this.riskAnalysis,
    required this.finalNotes,
    required this.rawMarkdown,
    this.chartImagePath,
  });

  /// Build from the JSON that OpenAI returns
  factory ChartAnalysis.fromAiJson(Map<String, dynamic> json) {
    return ChartAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      assetType: json['asset_type'] as String? ?? 'Unknown',
      pair: json['pair'] as String? ?? '—',
      sentiment: json['sentiment'] as String? ?? 'Neutral',
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.5,
      volumeScore: (json['volume_score'] as num?)?.toDouble() ?? 0.5,
      volumeLabel: json['volume_label'] as String? ?? 'Medium',
      summary: json['summary'] as String? ?? '',
      keyLevels: json['key_levels'] as String? ?? '',
      tradeScenario: json['trade_scenario'] as String? ?? '',
      riskAnalysis: json['risk_analysis'] as String? ?? '',
      finalNotes: json['final_notes'] as String? ?? '',
      rawMarkdown: json['raw_markdown'] as String? ?? '',
      chartImagePath: json['chart_image_path'] as String?,
    );
  }

  factory ChartAnalysis.fromJson(Map<String, dynamic> json) {
    return ChartAnalysis(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      assetType: json['asset_type'] as String,
      pair: json['pair'] as String,
      sentiment: json['sentiment'] as String,
      sentimentScore: (json['sentiment_score'] as num).toDouble(),
      volumeScore: (json['volume_score'] as num).toDouble(),
      volumeLabel: json['volume_label'] as String,
      summary: json['summary'] as String,
      keyLevels: json['key_levels'] as String,
      tradeScenario: json['trade_scenario'] as String,
      riskAnalysis: json['risk_analysis'] as String,
      finalNotes: json['final_notes'] as String,
      rawMarkdown: json['raw_markdown'] as String,
      chartImagePath: json['chart_image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'asset_type': assetType,
        'pair': pair,
        'sentiment': sentiment,
        'sentiment_score': sentimentScore,
        'volume_score': volumeScore,
        'volume_label': volumeLabel,
        'summary': summary,
        'key_levels': keyLevels,
        'trade_scenario': tradeScenario,
        'risk_analysis': riskAnalysis,
        'final_notes': finalNotes,
        'raw_markdown': rawMarkdown,
        'chart_image_path': chartImagePath,
      };

  String encode() => jsonEncode(toJson());

  static ChartAnalysis decode(String source) =>
      ChartAnalysis.fromJson(jsonDecode(source) as Map<String, dynamic>);

  bool get isBullish => sentiment.toLowerCase() == 'bullish';
  bool get isBearish => sentiment.toLowerCase() == 'bearish';
}

/// A single candlestick data point for the live chart
class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleData.fromBinance(List<dynamic> raw) {
    return CandleData(
      time: DateTime.fromMillisecondsSinceEpoch(raw[0] as int),
      open: double.parse(raw[1] as String),
      high: double.parse(raw[2] as String),
      low: double.parse(raw[3] as String),
      close: double.parse(raw[4] as String),
      volume: double.parse(raw[5] as String),
    );
  }
}
