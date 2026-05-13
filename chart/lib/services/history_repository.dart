import 'package:shared_preferences/shared_preferences.dart';

import '../models/chart_analysis.dart';

/// Persists analysis history locally using SharedPreferences
class HistoryRepository {
  static final HistoryRepository instance = HistoryRepository._();
  HistoryRepository._();

  static const String _key = 'chart_analysis_history_v2';

  Future<List<ChartAnalysis>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data
        .map((e) {
          try {
            return ChartAnalysis.decode(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<ChartAnalysis>()
        .toList();
  }

  Future<void> add(ChartAnalysis analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final updated = [analysis, ...existing];
    // Keep at most 100 items
    final trimmed = updated.take(100).toList();
    await prefs.setStringList(_key, trimmed.map((e) => e.encode()).toList());
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final updated = existing.where((e) => e.id != id).toList();
    await prefs.setStringList(_key, updated.map((e) => e.encode()).toList());
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
