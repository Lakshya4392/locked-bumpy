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
import '../widgets/staggered_fade_slide.dart';

/// Today tab — clean, clutter-free Nursery Hero + baby quote + 3 airy check-in row cards.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.state});

  final AppState state;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with TickerProviderStateMixin {
  late AnimationController _hopController;
  late Animation<double> _hopAnimation;
  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;

  List<ContentRecord>? _records;
  bool _hopping = false;
  int? _nudgeIndex;
  bool _showLove = false;

  static const List<String> _everydayNudges = [
    "Mommy, don't forget your prenatal vitamin today!",
    'Mommy, take a cozy sip of water for both of us.',
    "I'm stretching in here — rest your feet a bit, Mommy!",
    'Mommy, remember your medicine & a gentle snack today.',
    'You are doing great, Mommy. I love hanging out with you!',
  ];

  static const List<String> _halloweenNudges = [
    "Mommy, don't forget your magic vitamin potion today!",
    'Boo! Just checking if Mommy sipped her water.',
    'Resting my tiny bones — take a cozy break, Mommy!',
    'Mommy, keep an eye on your medicine & treats today!',
    'Even tiny spooky babies need extra cuddles, Mommy!',
  ];

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

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _wiggleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.07), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.07, end: 0.07), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.07, end: -0.03), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 20),
    ]).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );

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
    _wiggleController.dispose();
    super.dispose();
  }

  Future<void> _playBabyAntic({bool cycleNudge = false}) async {
    if (cycleNudge && mounted) {
      setState(() {
        _nudgeIndex = ((_nudgeIndex ?? -1) + 1) % _everydayNudges.length;
        _showLove = true;
      });
    }
    if (_hopping) return;
    _hopping = true;
    await Future.wait([
      _hopController.forward(from: 0),
      _wiggleController.forward(from: 0),
    ]);
    _hopping = false;
    if (mounted && _showLove) {
      setState(() => _showLove = false);
    }
  }

  Future<void> _onCheckIn(String id) async {
    final wasChecked = widget.state.isChecked(id);
    await widget.state.toggleCheckIn(id);
    if (mounted) {
      setState(() {
        _nudgeIndex = null;
      });
    }

    if (!wasChecked) {
      await _playBabyAntic();
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

  String _titleCaseNeed(MaternalNeed need) =>
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
    final nudges = palette.isHalloween ? _halloweenNudges : _everydayNudges;
    final babyLine = _nudgeIndex != null
        ? nudges[_nudgeIndex!]
        : _babyLine(need, needTicked, allDone, palette);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Separate Open Nursery Stage + Bumpy (tap Bumpy for playful reminders)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: palette.isHalloween ? 0.34 : 0.06,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => _playBabyAntic(cycleNudge: true),
              child: NurseryStage(
                need: avatarNeed,
                tone: state.babyTone,
                expression: _babyExpression(needTicked, allDone),
                hopAnimation: _hopAnimation,
                wiggleAnimation: _wiggleAnimation,
                showSparkle: needTicked || allDone || _showLove,
                height: 288,
                avatarSize: 230,
                borderRadius: BorderRadius.circular(28),
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
                topRightBadge: GestureDetector(
                  onTap: () => ClosetSheet.show(context, state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: palette.paper.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.checkroom_rounded,
                          size: 13,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          palette.isHalloween ? 'Costumes' : 'Outfits',
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
          const SizedBox(height: 10),

          // ── Separate Baby Speech Pill (tap for another Mommy reminder) ──
          GestureDetector(
            onTap: () => _playBabyAntic(cycleNudge: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  need.color.withValues(
                    alpha: palette.isHalloween ? 0.16 : 0.09,
                  ),
                  palette.paper,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: palette.isHalloween ? 0.22 : 0.03,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      child: Text(
                        babyLine,
                        key: ValueKey(babyLine),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: palette.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _showLove
                        ? Icons.favorite_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 15,
                    color: palette.accent.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── 3 Clean Borderless Row Check-In Cards (Title-only + Big Icon) ─
          StaggeredFadeSlide(
            index: 1,
            child: _CheckInRowCard(
              title: _titleCaseNeed(need),
              need: need,
              isTicked: needTicked,
              palette: palette,
              onTap: () => _onCheckIn(AppConstants.checkInNeed),
            ),
          ),
          const SizedBox(height: 10),
          StaggeredFadeSlide(
            index: 2,
            child: _CheckInRowCard(
              title: 'Water',
              need: MaternalNeed.water,
              isTicked: waterTicked,
              palette: palette,
              onTap: () => _onCheckIn(AppConstants.checkInWater),
            ),
          ),
          const SizedBox(height: 10),
          StaggeredFadeSlide(
            index: 3,
            child: _CheckInRowCard(
              title: thirdNeed == MaternalNeed.rest
                  ? 'Rest'
                  : 'Prenatal Vitamin',
              need: thirdNeed == MaternalNeed.rest
                  ? MaternalNeed.rest
                  : MaternalNeed.vitamin,
              isTicked: vitaminTicked,
              palette: palette,
              onTap: () => _onCheckIn(AppConstants.checkInVitamin),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Clean Borderless Check-In Row Card (Big Icon + Title Only) ─────────────

class _CheckInRowCard extends StatelessWidget {
  const _CheckInRowCard({
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
    final bgColor = Color.alphaBlend(
      need.color.withValues(
        alpha: isTicked
            ? (palette.isHalloween ? 0.20 : 0.12)
            : (palette.isHalloween ? 0.06 : 0.045),
      ),
      palette.paper,
    );

    return Semantics(
      label: title,
      checked: isTicked,
      button: true,
      child: SpringTap(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: isTicked && palette.isHalloween
                    ? need.color.withValues(alpha: 0.28)
                    : Colors.black.withValues(
                        alpha: palette.isHalloween ? 0.25 : 0.04,
                      ),
                blurRadius: isTicked && palette.isHalloween ? 18 : 16,
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
              child: Container(
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    NeedIconBadge(need: need, size: 46, isCompleted: isTicked),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
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
                      ),
                      child: isTicked
                          ? Icon(
                              palette.isHalloween
                                  ? Icons.auto_awesome_rounded
                                  : Icons.check_rounded,
                              size: 17,
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
      ),
    );
  }
}
