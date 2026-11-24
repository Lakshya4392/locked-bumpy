import 'package:flutter/services.dart' show rootBundle;
import '../domain/models/content_record.dart';
import '../domain/models/guide_article.dart';
import '../domain/models/need.dart';
import '../domain/models/week_card.dart';

/// Loads and validates content packs from bundled JSON assets.
///
/// All assets are offline (bundled with the app via `rootBundle`).
/// No network calls, no runtime AI. Results are cached after first load.
class ContentLoader {
  ContentLoader._();

  static final Map<String, List<ContentRecord>> _cache = {};

  /// Loads the individually reviewed records in [assetPath] (e.g.
  /// `'assets/content/today_lines.json'`). Returns cached result on
  /// subsequent calls.
  static Future<List<ContentRecord>> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath]!;
    final raw = await rootBundle.loadString(assetPath);
    final records = ContentRecord.listFromJsonString(raw);
    final validated = List<ContentRecord>.unmodifiable(
      records.where(ContentGate.canDisplay),
    );
    _cache[assetPath] = validated;
    return validated;
  }

  /// Clears the in-memory cache. Used in tests only.
  static void clearCache() {
    _cache.clear();
    _weekCards = null;
  }

  static List<WeekCard>? _weekCards;

  static Future<List<WeekCard>> loadWeekCards() async {
    final cached = _weekCards;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/content/week_cards.json');
    return _weekCards = List.unmodifiable(WeekCard.listFromJsonString(raw));
  }

  static Future<Map<MaternalNeed, GuideArticle>> loadGuides() async {
    final raw = await rootBundle.loadString(
      'assets/content/guide_articles.json',
    );
    return GuideArticle.reviewed(raw, reviewer: 'Karan');
  }

  // ── Query helpers ─────────────────────────────────────────────────────────

  /// Finds the first approved record matching [need], [category], and [mode].
  ///
  /// Mode matching: a record with `mode == 'both'` matches any [mode] value.
  /// Returns `null` if no match is found.
  static ContentRecord? find({
    required List<ContentRecord> records,
    required String need,
    required String category,
    required String mode, // 'everyday' | 'halloween'
  }) {
    for (final r in records) {
      if (r.need != need) continue;
      if (r.category != category) continue;
      if (r.mode != 'both' && r.mode != mode) continue;
      return r;
    }
    return null;
  }

  /// Like [find] but throws [StateError] when no matching record exists.
  static ContentRecord require({
    required List<ContentRecord> records,
    required String need,
    required String category,
    required String mode,
  }) {
    final r = find(
      records: records,
      need: need,
      category: category,
      mode: mode,
    );
    if (r == null) {
      throw StateError(
        'No approved content record for need=$need '
        'category=$category mode=$mode',
      );
    }
    return r;
  }
}
