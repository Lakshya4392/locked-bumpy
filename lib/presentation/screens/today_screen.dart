import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/content_record.dart';
import '../../domain/models/need.dart';
import '../widgets/baby_avatar.dart';

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

  /// Cached today-lines once loaded.
  List<ContentRecord>? _records;

  bool _hopping = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -18,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -18,
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

  // ── Line resolution ───────────────────────────────────────────────────────

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
    // Fallback while records are loading (first frame only).
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Baby card ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.paper,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Costume tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: need.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: need.color, width: 1.5),
                  ),
                  child: Text(
                    need.tag(palette),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: palette.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Baby avatar
                BabyAvatar(
                  need: avatarNeed,
                  size: 120,
                  hopAnimation: _hopAnimation,
                ),
                const SizedBox(height: 14),

                // Baby speech
                Text(
                  babyLine,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: palette.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Check-ins header ────────────────────────────────────────────
          Text(
            "Today's 3 Check-Ins",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.moonlightSoft,
            ),
          ),
          const SizedBox(height: 10),

          // Check-in 1 — Need of the Day
          _CheckInTile(
            id: AppConstants.checkInNeed,
            title: '${need.needName} · Need of the Day',
            subtitle: need.foodHint,
            needColor: need.color,
            isTicked: needTicked,
            palette: palette,
            onTap: () => _onCheckIn(AppConstants.checkInNeed),
          ),
          const SizedBox(height: 8),

          // Check-in 2 — Water
          _CheckInTile(
            id: AppConstants.checkInWater,
            title: 'Water',
            subtitle: MaternalNeed.water.foodHint,
            needColor: AppPalette.needWater,
            isTicked: state.isChecked(AppConstants.checkInWater),
            palette: palette,
            onTap: () => _onCheckIn(AppConstants.checkInWater),
          ),
          const SizedBox(height: 8),

          // Check-in 3 — Vitamin OR Rest
          _CheckInTile(
            id: AppConstants.checkInVitamin,
            title: thirdNeed == MaternalNeed.rest ? 'Rest' : 'Prenatal Vitamin',
            subtitle: thirdNeed == MaternalNeed.rest
                ? MaternalNeed.rest.foodHint
                : MaternalNeed.vitamin.foodHint,
            needColor: thirdNeed == MaternalNeed.rest
                ? AppPalette.needRest
                : AppPalette.needVitamin,
            isTicked: state.isChecked(AppConstants.checkInVitamin),
            palette: palette,
            onTap: () => _onCheckIn(AppConstants.checkInVitamin),
          ),

          if (allDone) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                babyLine,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text(
            AppConstants.disclaimer,
            style: TextStyle(
              fontSize: 11,
              color: palette.moonlightSoft.withValues(alpha: 0.7),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Reusable check-in tile ─────────────────────────────────────────────────

class _CheckInTile extends StatelessWidget {
  const _CheckInTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.needColor,
    required this.isTicked,
    required this.palette,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color needColor;
  final bool isTicked;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title check-in',
      checked: isTicked,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: palette.paperRaised,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: palette.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: palette.inkSoft),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isTicked ? palette.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTicked ? palette.accent : palette.inkSoft,
                    width: 2,
                  ),
                ),
                child: isTicked
                    ? Icon(Icons.star, size: 16, color: palette.accentText)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
