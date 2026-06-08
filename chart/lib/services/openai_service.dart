import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';
import '../models/chart_analysis.dart';

/// Handles all communication with the OpenAI Vision API.
///
/// The API key is sourced exclusively from [AppConstants.openAiApiKey],
/// which is either supplied at build-time via --dart-define=OPENAI_API_KEY=sk-...
/// or falls back to the 'YOUR_API_KEY_HERE' placeholder.
class OpenAiService {
  static final OpenAiService instance = OpenAiService._();
  OpenAiService._();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.openAiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );

  /// Infer MIME type from file extension (avoids the mime package).
  static String _mimeFromPath(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  /// The structured prompt — instructs GPT-4o-mini to return strict JSON only.
  static const String _analysisPrompt = '''
You are an expert financial chart analyst specialising in technical analysis.
Analyse the provided chart image and return ONLY a JSON object — no markdown fences, no preamble, no extra text.

JSON structure (all fields required):
{
  "asset_type": "<Crypto | Forex | Stocks | Unknown>",
  "pair": "<detected trading pair or 'Unknown'>",
  "sentiment": "<Bullish | Bearish | Neutral>",
  "sentiment_score": <0.0 to 1.0>,
  "volume_score": <0.0 to 1.0>,
  "volume_label": "<Low | Medium | High>",
  "summary": "<2–3 sentence overall market summary>",
  "key_levels": "<markdown bullet list of support and resistance levels>",
  "trade_scenario": "<markdown describing bullish and bearish trade setups>",
  "risk_analysis": "<markdown risk assessment including risk level: Low/Medium/High>",
  "final_notes": "<markdown closing technical observations>",
  "raw_markdown": "<complete analysis in markdown with these exact section headings:\\n## Overall Summary\\n## Market Sentiment\\n## Key Levels\\n## Trade Scenario\\n## Risk Analysis\\n## Final Notes>"
}

Analyse these aspects if visible on the chart:
- Trend direction (uptrend / downtrend / sideways)
- Market structure (higher highs/lows, consolidation, range)
- Key support and resistance levels (price values if readable)
- Breakout and breakdown possibilities
- Candlestick patterns (doji, hammer, engulfing, shooting star, etc.)
- Chart patterns (H&S, double top/bottom, wedge, triangle, flag, pennant, etc.)
- RSI observations (overbought/oversold) if indicator is visible
- MACD observations (crossovers, divergence) if indicator is visible
- EMA/SMA overlay observations if visible
- Volume and momentum analysis
- Bullish vs bearish probability estimate
- Overall risk level

If the image is not a financial chart, set sentiment to "Neutral", sentiment_score to 0.5, and explain in summary that a valid chart image is required.
''';

  /// Analyse a chart [imageFile] using GPT-4o Vision.
  Future<ChartAnalysis> analyzeChart(File imageFile) async {
    final apiKey = AppConstants.openAiApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'OpenAI API key is not configured. '
        'Supply it via --dart-define=OPENAI_API_KEY=sk-...',
      );
    }

    final mimeType = _mimeFromPath(imageFile.path);
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$base64Image';

    final response = await _dio.post(
      '/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': AppConstants.openAiModel,
        'max_tokens': 2000,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': _analysisPrompt},
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl, 'detail': 'high'},
              },
            ],
          },
        ],
      },
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      String answer =
          (data['choices'] as List).first['message']['content'] as String;

      // Strip markdown code fences if the model adds them despite instructions.
      answer = answer.trim();
      if (answer.startsWith('```')) {
        answer = answer
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
            .replaceAll('```', '')
            .trim();
      }

      final Map<String, dynamic> parsed =
          jsonDecode(answer) as Map<String, dynamic>;
      return ChartAnalysis.fromAiJson(parsed);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'OpenAI API error: ${response.statusCode}',
      );
    }
  }

  /// Convert any caught error into a user-friendly message.
  static String friendlyError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Request timed out. Please check your internet connection and try again.';
      }
      final status = error.response?.statusCode;
      if (status == 401) {
        return 'Invalid API key. Please check the configured OpenAI key.';
      }
      if (status == 429) {
        return 'Rate limit exceeded. Please wait a moment and try again.';
      }
      if (status == 500) {
        return 'OpenAI server error. Please try again in a moment.';
      }
      if (status == 413) {
        return 'Image is too large. Please use a smaller or compressed image.';
      }
      return 'API error ($status). Please try again.';
    }
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      return msg;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
