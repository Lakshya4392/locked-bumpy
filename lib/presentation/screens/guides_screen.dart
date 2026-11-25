import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/guide_article.dart';

/// Guides tab — 6 physician-authored maternal care guides.
/// Uses calm, plain-English app voice (no baby voice, no clinical doses).
class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  static List<GuideArticle>? _cachedArticles;
  List<GuideArticle>? _articles;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    if (_cachedArticles != null) {
      _articles = _cachedArticles;
    } else {
      _loadArticles();
    }
  }

  Future<void> _loadArticles() async {
    final raw = await rootBundle.loadString(
      'assets/content/guide_articles.json',
    );
    final loaded = GuideArticle.listFromJsonString(raw);
    _cachedArticles = loaded;
    if (mounted) {
      setState(() {
        _articles = loaded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final articles = _articles;

    if (articles == null) {
      return Center(
        child: Text(
          'Loading guides...',
          style: TextStyle(color: palette.moonlightSoft),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Text(
          'Maternal Care Guides',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: palette.moonlight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gentle nutrition and care notes. Vegetarian & egg-free ideas.',
          style: TextStyle(fontSize: 13, color: palette.moonlightSoft),
        ),
        const SizedBox(height: 16),
        ...articles.map((article) {
          final isExpanded = _expandedId == article.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GuideCard(
              article: article,
              isExpanded: isExpanded,
              palette: palette,
              onTap: () {
                setState(() {
                  _expandedId = isExpanded ? null : article.id;
                });
              },
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(
          AppConstants.disclaimer,
          style: TextStyle(
            fontSize: 11,
            color: palette.moonlightSoft.withValues(alpha: 0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.article,
    required this.isExpanded,
    required this.palette,
    required this.onTap,
  });

  final GuideArticle article;
  final bool isExpanded;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needColor = article.maternalNeed.color;

    return Semantics(
      label: '${article.title} guide',
      expanded: isExpanded,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: BorderRadius.circular(20),
            border: isExpanded
                ? Border.all(
                    color: needColor.withValues(alpha: 0.7),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: needColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.ink, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.ink,
                          ),
                        ),
                        Text(
                          article.summary,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: palette.inkSoft,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                Divider(color: palette.inkSoft.withValues(alpha: 0.2)),
                const SizedBox(height: 10),
                Text(
                  article.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: palette.ink,
                  ),
                ),
                if (article.foodIdeas.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Gentle ideas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...article.foodIdeas.map(
                    (idea) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: palette.accent,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              idea,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.inkSoft,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (article.questionsForDoctor.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.paperRaised,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questions for your doctor',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...article.questionsForDoctor.map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '— $q',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.inkSoft,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
