import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/content_record.dart';
import '../../domain/models/need.dart';
import '../widgets/need_icon_badge.dart';
import '../widgets/nursery_stage.dart';

/// Today tab — daily loop under 30 seconds.
/// Baby-voice lines are loaded from [ContentLoader] (bundled JSON, offline).
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = widget.state;
    final need = state.todayNeed;
    final avatarNeed = state.costumeOverride ?? need;
    final thirdNeed = state.thirdCheckIn;
    final needTicked = state.isChecked(AppConstants.checkInNeed);
    final allDone = state.allChecked;
    final babyLine = _babyLine(need, needTicked, allDone, palette);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Illustrated Nursery Hero Card ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
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
                NurseryStage(
                  need: avatarNeed,
                  tone: state.babyTone,
                  expression: _babyExpression(needTicked, allDone),
                  hopAnimation: _hopAnimation,
                  showSparkle: needTicked || allDone,
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
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    babyLine,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: palette.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SizedBox(height: 18),

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

          // Check-in 1 — Need of the Day
          _CheckInTile(
            title: '${need.needName} · Need of the Day',
            subtitle: need.foodHint,
            need: need,
            isTicked: needTicked,
            palette: palette,
            onTap: () => _onCheckIn(AppConstants.checkInNeed),
          ),
          const SizedBox(height: 10),

          // Check-in 2 — Water
          _CheckInTile(
            title: 'Water',
            subtitle: MaternalNeed.water.foodHint,
            need: MaternalNeed.water,
            isTicked: state.isChecked(AppConstants.checkInWater),
            palette: palette,
            onTap: () => _onCheckIn(AppConstants.checkInWater),
          ),
          const SizedBox(height: 10),

          // Check-in 3 — Vitamin OR Rest
          _CheckInTile(
            title: thirdNeed == MaternalNeed.rest ? 'Rest' : 'Prenatal Vitamin',
            subtitle: thirdNeed == MaternalNeed.rest
                ? MaternalNeed.rest.foodHint
                : MaternalNeed.vitamin.foodHint,
            need: thirdNeed == MaternalNeed.rest
                ? MaternalNeed.rest
                : MaternalNeed.vitamin,
            isTicked: state.isChecked(AppConstants.checkInVitamin),
            palette: palette,
            onTap: () => _onCheckIn(AppConstants.checkInVitamin),
          ),

          if (allDone) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                babyLine,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 18),
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

// ── Reusable check-in tile ─────────────────────────────────────────────────

class _CheckInTile extends StatelessWidget {
  const _CheckInTile({
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
      child: Material(
        color: palette.paper,
        borderRadius: BorderRadius.circular(22),
        elevation: palette.isHalloween ? 2 : 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: isTicked
                  ? Border.all(
                      color: need.color.withValues(alpha: 0.55),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                NeedIconBadge(need: need, size: 46, isCompleted: isTicked),
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
                        style: TextStyle(fontSize: 12, color: palette.inkSoft),
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
    );
  }
}
