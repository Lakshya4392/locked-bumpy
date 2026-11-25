import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/content_record.dart';
import '../../domain/models/need.dart';
import '../../domain/pregnancy.dart';
import '../sheets/closet_sheet.dart';
import '../widgets/need_icon_badge.dart';
import '../widgets/nursery_stage.dart';
import '../widgets/spring_tap.dart';

/// Today tab — editorial greeting, full-bleed Nursery Hero, inline circular
/// check-in strip (inspired by clean wellness check-in bar), and "For you" 2-card row.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.state});

  final AppState state;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _hopController;
  late Animation<double> _hopAnimation;

  List<ContentRecord>? _records;
  bool _hopping = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -16,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -16,
          end: 0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_hopController);

    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await ContentLoader.load('assets/content/today_lines.json');
    if (mounted) setState(() => _records = records);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _hopController.dispose();
    super.dispose();
  }

  Future<void> _onCheckIn(String id) async {
    final wasChecked = widget.state.isChecked(id);
    await widget.state.toggleCheckIn(id);
    if (mounted) setState(() {});

    if (id == AppConstants.checkInNeed && !wasChecked && !_hopping) {
      _hopping = true;
      await _hopController.forward(from: 0);
      _hopping = false;
    }
  }

  // ── Line & expression resolution ──────────────────────────────────────────

  String _babyLine(
    MaternalNeed need,
    bool needTicked,
    bool allDone,
    AppPalette palette,
  ) {
    if (allDone) return _goodbye(palette);
    final category = needTicked ? 'thank_you' : 'greeting';
    final mode = palette.isHalloween ? 'halloween' : 'everyday';
    if (_records != null) {
      final r = ContentLoader.find(
        records: _records!,
        need: need.needName,
        category: category,
        mode: mode,
      );
      if (r != null) return r.text;
    }
    return needTicked ? 'Thank you!' : need.foodHint;
  }

  String _goodbye(AppPalette palette) {
    if (_records != null) {
      final r = ContentLoader.find(
        records: _records!,
        need: 'ALL',
        category: 'goodbye',
        mode: palette.isHalloween ? 'halloween' : 'everyday',
      );
      if (r != null) return r.text;
    }
    return "That's us for today.";
  }

  String _babyExpression(bool needTicked, bool allDone) {
    if (allDone) return 'big-smile';
    if (needTicked) return 'delighted';
    return 'calm';
  }

  String _shortNeedTitle(MaternalNeed need) =>
      need.needName[0] + need.needName.substring(1).toLowerCase();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = widget.state;
    final need = state.todayNeed;
    final avatarNeed = state.costumeOverride ?? need;
    final thirdNeed = state.thirdCheckIn;
    final needTicked = state.isChecked(AppConstants.checkInNeed);
    final waterTicked = state.isChecked(AppConstants.checkInWater);
    final vitaminTicked = state.isChecked(AppConstants.checkInVitamin);
    final allDone = state.allChecked;
    final babyLine = _babyLine(need, needTicked, allDone, palette);
    final week = state.dueDate == null
        ? 4
        : PregnancyCalculator.weekFromDueDate(
            dueDate: state.dueDate!,
            currentDate: DateTime.now(),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Editorial Headline ──────────────────────────────────────────
          Text(
            'How have things\nbeen today?',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.4,
              color: palette.moonlight,
            ),
          ),
          const SizedBox(height: 14),

          // ── Illustrated Hero Stage + Inline Check-In Strip ──────────────
          Container(
            decoration: BoxDecoration(
              color: palette.paper,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: palette.isHalloween ? 0.32 : 0.05,
                  ),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => ClosetSheet.show(context, state),
                  child: NurseryStage(
                    need: avatarNeed,
                    tone: state.babyTone,
                    expression: _babyExpression(needTicked, allDone),
                    hopAnimation: _hopAnimation,
                    showSparkle: needTicked || allDone,
                    height: 215,
                    avatarSize: 176,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    topLeftBadge: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.paper.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: need.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            need.tag(palette),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: palette.ink,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Inline Check-In Bar (Reference: "How do you feel?" + circular icons)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: Column(
                            key: ValueKey(babyLine),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                babyLine,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: palette.ink,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to log today',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: palette.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _InlineCheckButton(
                        title: _shortNeedTitle(need),
                        need: need,
                        isTicked: needTicked,
                        palette: palette,
                        onTap: () => _onCheckIn(AppConstants.checkInNeed),
                      ),
                      const SizedBox(width: 8),
                      _InlineCheckButton(
                        title: 'Water',
                        need: MaternalNeed.water,
                        isTicked: waterTicked,
                        palette: palette,
                        onTap: () => _onCheckIn(AppConstants.checkInWater),
                      ),
                      const SizedBox(width: 8),
                      _InlineCheckButton(
                        title: thirdNeed == MaternalNeed.rest
                            ? 'Rest'
                            : 'Vitamin',
                        need: thirdNeed == MaternalNeed.rest
                            ? MaternalNeed.rest
                            : MaternalNeed.vitamin,
                        isTicked: vitaminTicked,
                        palette: palette,
                        onTap: () => _onCheckIn(AppConstants.checkInVitamin),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── "For you" 2-Card Editorial Section ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'For you',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: palette.moonlight,
                ),
              ),
              GestureDetector(
                onTap: () => state.setTab(2),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: palette.moonlightSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _ForYouCard(
                  eyebrow: 'Week $week · ${state.babyDisplayName}',
                  title: 'This Week\nGrowth Note',
                  palette: palette,
                  tint: palette.isHalloween
                      ? const Color(0xFF3A2A52)
                      : const Color(0xFFF3EFEA),
                  preview: Image.asset(
                    NeedIconBadge.iconPathFor(MaternalNeed.rest),
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                  onTap: () => state.setTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ForYouCard(
                  eyebrow: '6 Guides · Offline',
                  title: 'Maternal\nCare Guides',
                  palette: palette,
                  tint: palette.isHalloween
                      ? const Color(0xFF322548)
                      : const Color(0xFFEEF3EE),
                  preview: Image.asset(
                    NeedIconBadge.iconPathFor(need),
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                  onTap: () => state.setTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Inline Circular Check-In Icon Button ───────────────────────────────────

class _InlineCheckButton extends StatelessWidget {
  const _InlineCheckButton({
    required this.title,
    required this.need,
    required this.isTicked,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final MaternalNeed need;
  final bool isTicked;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      checked: isTicked,
      button: true,
      child: SpringTap(
        onTap: onTap,
        pressedScale: 0.9,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  NeedIconBadge(need: need, size: 46, isCompleted: isTicked),
                  if (isTicked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.paper, width: 1.5),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: palette.accentText,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── "For you" Editorial Card (matches reference bottom cards) ──────────────

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({
    required this.eyebrow,
    required this.title,
    required this.palette,
    required this.tint,
    required this.preview,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final AppPalette palette;
  final Color tint;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isHalloween ? 0.25 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: palette.paper,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 76,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(child: preview),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eyebrow,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: palette.inkSoft,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: palette.accentText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
