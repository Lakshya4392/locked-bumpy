import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../widgets/visit_topics.dart';
import '../../domain/models/guide_article.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import '../widgets/bumpy_avatar.dart';

/// The details stay inside the main shell so Pause immediately hides them.
class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  late final _articles = ContentLoader.loadGuides();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return FutureBuilder<Map<MaternalNeed, GuideArticle>>(
      future: _articles,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            header: true,
            child: Text(
              snapshot.data?.isNotEmpty == true ? 'Care guides' : 'Care topics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.moonlight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          VisitTopics(state: widget.state),
          const SizedBox(height: 16),
          for (final need in [
            widget.state.todayNeed,
            ...MaternalNeed.values.where((n) => n != widget.state.todayNeed),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NeedGuide(
                need: need,
                isToday: need == widget.state.todayNeed,
                palette: palette,
                article: snapshot.data?[need],
                skinTone: widget.state.skinTone,
                savedForVisit: widget.state.visitTopics.contains(need),
                onVisitList: () =>
                    VisitTopics.edit(context, widget.state, include: need),
              ),
            ),
          Text(
            AppConstants.disclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.moonlightSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NeedGuide extends StatelessWidget {
  const _NeedGuide({
    required this.need,
    required this.isToday,
    required this.palette,
    required this.article,
    required this.skinTone,
    required this.savedForVisit,
    required this.onVisitList,
  });
  final MaternalNeed need;
  final bool isToday;
  final AppPalette palette;
  final GuideArticle? article;
  final SkinTone skinTone;
  final bool savedForVisit;
  final VoidCallback onVisitList;

  @override
  Widget build(BuildContext context) {
    final copy = article;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return Material(
      shape: shape,
      clipBehavior: Clip.antiAlias,
      color: palette.paper,
      child: ExpansionTile(
        key: PageStorageKey(need),
        expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        shape: shape,
        collapsedShape: shape,
        iconColor: palette.ink,
        collapsedIconColor: palette.inkSoft,
        leading: Image.asset(
          need.iconPath,
          width: 40,
          height: 40,
          excludeFromSemantics: true,
        ),
        title: Text(
          need.label,
          style: TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
        ),
        subtitle: isToday || savedForVisit
            ? Text(
                [
                  if (isToday) 'Today’s need',
                  if (savedForVisit) 'On your visit list',
                ].join(' · '),
                style: TextStyle(color: palette.inkSoft),
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: BumpyAvatar(
              need: need,
              palette: palette,
              happy: false,
              skinTone: skinTone,
            ),
          ),
          if (palette.isHalloween)
            Text(
              need.costume,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (copy != null) ...[
            const SizedBox(height: 12),
            Text(copy.body, style: TextStyle(color: palette.ink, height: 1.4)),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                'Questions to ask your doctor',
                style: TextStyle(
                  color: palette.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final question in copy.questions)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(question, style: TextStyle(color: palette.inkSoft)),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onVisitList,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.ink,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: Icon(savedForVisit ? Icons.bookmark : Icons.bookmark_outline),
            label: Text(
              savedForVisit ? 'On my visit list' : 'Add to my visit list',
            ),
          ),
        ],
      ),
    );
  }
}
