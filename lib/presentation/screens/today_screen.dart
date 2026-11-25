import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/content_record.dart';
import '../../domain/models/need.dart';
import '../sheets/closet_sheet.dart';
import '../widgets/need_icon_badge.dart';
import '../widgets/nursery_stage.dart';
import '../widgets/spring_tap.dart';

/// Today tab — warm illustrated nursery stage, speech bubble, quick outfit strip,
/// featured Need of the Day card, and side-by-side Water / Vitamin bento tiles.
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

  String _outfitLabel(MaternalNeed need, AppPalette palette) {
    if (palette.isHalloween) {
      return need.costume[0] + need.costume.substring(1).toLowerCase();
    }
    return switch (need) {
      MaternalNeed.iron => 'Sailor',
      MaternalNeed.brain => 'Story',
      MaternalNeed.bones => 'Cozy',
      MaternalNeed.water => 'Petal',
      MaternalNeed.rest => 'Snuggle',
      MaternalNeed.vitamin => 'Clap',
    };
  }

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Illustrated Nursery Hero Card ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.paper,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: palette.isHalloween ? 0.3 : 0.06,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: palette.isHalloween
                      ? () => ClosetSheet.show(context, state)
                      : null,
                  child: NurseryStage(
                    need: avatarNeed,
                    tone: state.babyTone,
                    expression: _babyExpression(needTicked, allDone),
                    hopAnimation: _hopAnimation,
                    showSparkle: needTicked || allDone,
                    height: 205,
                    avatarSize: 162,
                    topLeftBadge: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.paper.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: need.color.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
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
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Speech bubble
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.paperRaised,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    child: Text(
                      babyLine,
                      key: ValueKey(babyLine),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: palette.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick 6-outfit / costume strip (parity across both modes)
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: MaternalNeed.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final m = MaternalNeed.values[i];
                      final isSelected = avatarNeed == m;
                      return ChoiceChip(
                        label: Text(
                          _outfitLabel(m, palette),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? palette.accentText
                                : palette.inkSoft,
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: palette.accent,
                        backgroundColor: palette.paperRaised,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        onSelected: (_) =>
                            state.setCostumeOverride(m == need ? null : m),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Check-ins header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's 3 Check-Ins",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: palette.moonlight,
                  ),
                ),
                Text(
                  '${state.completedCheckIns.length} of 3',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.moonlightSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Check-in 1 — Featured Need of the Day card
          _FeaturedCheckInCard(
            title: '${need.needName} · Need of the Day',
            subtitle: need.foodHint,
            need: need,
            isTicked: needTicked,
            palette: palette,
            onTap: () => _onCheckIn(AppConstants.checkInNeed),
          ),
          const SizedBox(height: 10),

          // Check-ins 2 & 3 — Side-by-side Bento Tiles
          Row(
            children: [
              Expanded(
                child: _BentoCheckInTile(
                  title: 'Water',
                  subtitle: 'Refreshing glass',
                  need: MaternalNeed.water,
                  isTicked: waterTicked,
                  palette: palette,
                  onTap: () => _onCheckIn(AppConstants.checkInWater),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BentoCheckInTile(
                  title: thirdNeed == MaternalNeed.rest
                      ? 'Rest'
                      : 'Prenatal Vitamin',
                  subtitle: thirdNeed == MaternalNeed.rest
                      ? 'Feet up for five'
                      : 'Doctor chosen',
                  need: thirdNeed == MaternalNeed.rest
                      ? MaternalNeed.rest
                      : MaternalNeed.vitamin,
                  isTicked: vitaminTicked,
                  palette: palette,
                  onTap: () => _onCheckIn(AppConstants.checkInVitamin),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            AppConstants.disclaimer,
            style: TextStyle(
              fontSize: 11,
              color: palette.moonlightSoft.withValues(alpha: 0.8),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Featured Need of the Day Card ──────────────────────────────────────────

class _FeaturedCheckInCard extends StatelessWidget {
  const _FeaturedCheckInCard({
    required this.title,
    required this.subtitle,
    required this.need,
    required this.isTicked,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final MaternalNeed need;
  final bool isTicked;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title check-in',
      checked: isTicked,
      button: true,
      child: SpringTap(
        onTap: onTap,
        child: Material(
          color: palette.paper,
          borderRadius: BorderRadius.circular(22),
          elevation: palette.isHalloween ? 2 : 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isTicked
                    ? need.color.withValues(alpha: 0.09)
                    : Colors.transparent,
                border: Border.all(
                  color: isTicked
                      ? need.color.withValues(alpha: 0.6)
                      : need.color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  NeedIconBadge(need: need, size: 48, isCompleted: isTicked),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isTicked ? palette.accent : palette.paperRaised,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isTicked
                            ? palette.accent
                            : palette.inkSoft.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: isTicked
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: palette.accentText,
                          )
                        : null,
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

// ── Compact Bento Check-In Tile ────────────────────────────────────────────

class _BentoCheckInTile extends StatelessWidget {
  const _BentoCheckInTile({
    required this.title,
    required this.subtitle,
    required this.need,
    required this.isTicked,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final MaternalNeed need;
  final bool isTicked;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title check-in',
      checked: isTicked,
      button: true,
      child: SpringTap(
        onTap: onTap,
        child: Material(
          color: palette.paper,
          borderRadius: BorderRadius.circular(22),
          elevation: palette.isHalloween ? 2 : 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isTicked
                    ? need.color.withValues(alpha: 0.08)
                    : Colors.transparent,
                border: isTicked
                    ? Border.all(
                        color: need.color.withValues(alpha: 0.55),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NeedIconBadge(
                        need: need,
                        size: 40,
                        isCompleted: isTicked,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isTicked
                              ? palette.accent
                              : palette.paperRaised,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isTicked
                                ? palette.accent
                                : palette.inkSoft.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: isTicked
                            ? Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: palette.accentText,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: palette.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
