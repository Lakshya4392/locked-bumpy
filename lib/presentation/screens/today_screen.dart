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

/// Today tab — full-bleed nursery hero with Bumpy front-and-center,
/// editorial baby quote, and 3 equal-size borderless Bento check-in cards.
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

  String _shortNeedTitle(MaternalNeed need) =>
      need.needName[0] + need.needName.substring(1).toLowerCase();

  String _shortNeedHint(MaternalNeed need) {
    return switch (need) {
      MaternalNeed.iron => 'Lentils & beans',
      MaternalNeed.brain => 'Greens & nuts',
      MaternalNeed.bones => 'Milk or yogurt',
      MaternalNeed.water => 'Glass of water',
      MaternalNeed.rest => 'Five-min pause',
      MaternalNeed.vitamin => "Doctor's pick",
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Full-Bleed Nursery Hero Card ────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: palette.paper,
              borderRadius: BorderRadius.circular(28),
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
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => ClosetSheet.show(context, state),
                      child: NurseryStage(
                        need: avatarNeed,
                        tone: state.babyTone,
                        expression: _babyExpression(needTicked, allDone),
                        hopAnimation: _hopAnimation,
                        showSparkle: needTicked || allDone,
                        height: 276,
                        avatarSize: 212,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
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
                    // Subtle floating Outfit / Closet pill
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: SpringTap(
                        onTap: () => ClosetSheet.show(context, state),
                        child: Material(
                          color: palette.paper.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => ClosetSheet.show(context, state),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.checkroom_rounded,
                                    size: 14,
                                    color: palette.ink,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _outfitLabel(avatarNeed, palette),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: palette.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Editorial Baby Quote Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    child: Row(
                      key: ValueKey(babyLine),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: need.color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            babyLine,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: palette.ink,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 3 Equal-Size Borderless Bento Check-In Grid Cards ───────────
          Row(
            children: [
              Expanded(
                child: _GridCheckInCard(
                  title: _shortNeedTitle(need),
                  subtitle: _shortNeedHint(need),
                  need: need,
                  isTicked: needTicked,
                  palette: palette,
                  onTap: () => _onCheckIn(AppConstants.checkInNeed),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GridCheckInCard(
                  title: 'Water',
                  subtitle: _shortNeedHint(MaternalNeed.water),
                  need: MaternalNeed.water,
                  isTicked: waterTicked,
                  palette: palette,
                  onTap: () => _onCheckIn(AppConstants.checkInWater),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GridCheckInCard(
                  title: thirdNeed == MaternalNeed.rest ? 'Rest' : 'Vitamin',
                  subtitle: _shortNeedHint(
                    thirdNeed == MaternalNeed.rest
                        ? MaternalNeed.rest
                        : MaternalNeed.vitamin,
                  ),
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
              color: palette.moonlightSoft.withValues(alpha: 0.75),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ── Uniform Symmetrical Bento Grid Card ────────────────────────────────────

class _GridCheckInCard extends StatelessWidget {
  const _GridCheckInCard({
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
    final bgColor = isTicked
        ? Color.alphaBlend(
            need.color.withValues(alpha: palette.isHalloween ? 0.18 : 0.09),
            palette.paper,
          )
        : palette.paper;

    return Semantics(
      label: '$title check-in',
      checked: isTicked,
      button: true,
      child: SpringTap(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        NeedIconBadge(
                          need: need,
                          size: 46,
                          isCompleted: isTicked,
                        ),
                        if (isTicked)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: palette.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette.paper,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 11,
                                color: palette.accentText,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: palette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10.5, color: palette.inkSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
