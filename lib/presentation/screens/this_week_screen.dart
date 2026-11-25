import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../../domain/models/week_card.dart';
import '../../domain/pregnancy.dart';
import '../widgets/nursery_stage.dart';
import '../widgets/spring_tap.dart';

/// This Week tab — browse gestational weeks 4–42 with swipe, scrubber pill,
/// trimester progress bar, and full-bleed Nursery Stage.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  static List<WeekCard>? _cachedCards;
  List<WeekCard>? _cards;
  late int _selectedWeek;

  static const int _minWeek = AppConstants.minWeek; // 4
  static const int _maxWeek = AppConstants.maxWeek; // 42

  @override
  void initState() {
    super.initState();
    _selectedWeek = _currentWeek();
    if (_cachedCards != null) {
      _cards = _cachedCards;
    } else {
      _loadCards();
    }
  }

  int _currentWeek() {
    if (widget.state.dueDate == null) return _minWeek;
    return PregnancyCalculator.weekFromDueDate(
      dueDate: widget.state.dueDate!,
      currentDate: DateTime.now(),
    );
  }

  Future<void> _loadCards() async {
    final raw = await rootBundle.loadString('assets/content/week_cards.json');
    final loaded = WeekCard.listFromJsonString(raw);
    _cachedCards = loaded;
    if (mounted) setState(() => _cards = loaded);
  }

  String _trimesterLabel(int week) {
    if (week <= 12) return '1st Trimester';
    if (week <= 27) return '2nd Trimester';
    return '3rd Trimester';
  }

  void _stepWeek(int delta) {
    final next = (_selectedWeek + delta).clamp(_minWeek, _maxWeek);
    if (next != _selectedWeek) {
      setState(() => _selectedWeek = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final cards = _cards;

    if (cards == null) {
      return Center(
        child: Text(
          'Loading weeks...',
          style: TextStyle(color: palette.moonlightSoft),
        ),
      );
    }

    final mode = palette.isHalloween ? 'halloween' : 'everyday';
    final card = WeekCard.findFor(
      cards: cards,
      week: _selectedWeek,
      mode: mode,
    );
    final currentWeek = _currentWeek();
    final progress = ((_selectedWeek - _minWeek) / (_maxWeek - _minWeek)).clamp(
      0.05,
      1.0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        children: [
          // ── Week Scrubber Pill + Trimester Progress ─────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            decoration: BoxDecoration(
              color: palette.paper,
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Previous week',
                      enabled: _selectedWeek > _minWeek,
                      palette: palette,
                      onTap: () => _stepWeek(-1),
                    ),
                    Column(
                      children: [
                        Text(
                          'Week $_selectedWeek of 42',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _trimesterLabel(_selectedWeek),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    _NavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      label: 'Next week',
                      enabled: _selectedWeek < _maxWeek,
                      palette: palette,
                      onTap: () => _stepWeek(1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: palette.paperRaised,
                      valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Swipeable Full-Bleed Week Card ──────────────────────────────
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -250) {
                  _stepWeek(1);
                } else if (v > 250) {
                  _stepWeek(-1);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                child: _WeekCardView(
                  key: ValueKey(_selectedWeek),
                  week: _selectedWeek,
                  card: card,
                  palette: palette,
                  tone: widget.state.babyTone,
                  avatarNeed:
                      widget.state.costumeOverride ?? widget.state.todayNeed,
                  isCurrentWeek: _selectedWeek == currentWeek,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Trimester Quick-Jump Strip ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _JumpPill(
                label: '1st Tri',
                selected: _selectedWeek <= 12,
                palette: palette,
                onTap: () => setState(() => _selectedWeek = 8),
              ),
              _JumpPill(
                label: '2nd Tri',
                selected: _selectedWeek >= 13 && _selectedWeek <= 27,
                palette: palette,
                onTap: () => setState(() => _selectedWeek = 20),
              ),
              _JumpPill(
                label: '3rd Tri',
                selected: _selectedWeek >= 28,
                palette: palette,
                onTap: () => setState(() => _selectedWeek = 34),
              ),
              _JumpPill(
                label: 'Now (W$currentWeek)',
                selected: _selectedWeek == currentWeek,
                palette: palette,
                isHighlight: true,
                onTap: () => setState(() => _selectedWeek = currentWeek),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WeekCardView extends StatelessWidget {
  const _WeekCardView({
    super.key,
    required this.week,
    required this.card,
    required this.palette,
    required this.tone,
    required this.avatarNeed,
    required this.isCurrentWeek,
  });

  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final String tone;
  final MaternalNeed avatarNeed;
  final bool isCurrentWeek;

  String _mommyFocus(int week) {
    if (week <= 12) {
      return 'Early days: tiny sips of water, leafy greens or beans when you feel up to it, and your daily prenatal vitamin.';
    }
    if (week <= 27) {
      return 'Growing steady: calcium-rich bites like yogurt or cheese, plenty of water, and gentle rest whenever your body asks.';
    }
    return 'Home stretch: iron-rich snacks like lentils, steady hydration, and cozy breaks with your feet up.';
  }

  String _trimesterShort(int week) {
    if (week <= 12) return '1st Trimester';
    if (week <= 27) return '2nd Trimester';
    return '3rd Trimester';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (40 - week).clamp(0, 36);
    final remainingLabel = week >= 40
        ? 'Due window'
        : '$remaining wk${remaining == 1 ? '' : 's'} to 40';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isHalloween ? 0.3 : 0.05,
            ),
            offset: const Offset(0, 8),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        children: [
          NurseryStage(
            need: avatarNeed,
            tone: tone,
            expression: isCurrentWeek ? 'big-smile' : 'calm',
            height: 196,
            avatarSize: 166,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            topLeftBadge: isCurrentWeek
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'You are here',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette.accentText,
                      ),
                    ),
                  )
                : null,
            topRightBadge: card?.sizeObject != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: palette.paper.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Size of a ${card!.sizeObject}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    card?.babyLine ?? 'Week $week is on the way.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.38,
                      color: palette.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _WeekMetaPill(
                          icon: Icons.calendar_today_rounded,
                          label: _trimesterShort(week),
                          palette: palette,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _WeekMetaPill(
                          icon: Icons.favorite_border_rounded,
                          label: remainingLabel,
                          palette: palette,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: palette.paperRaised,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MOMMY'S GENTLE FOCUS",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _mommyFocus(week),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekMetaPill extends StatelessWidget {
  const _WeekMetaPill({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.paperRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13.5, color: palette.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _JumpPill extends StatelessWidget {
  const _JumpPill({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
    this.isHighlight = false,
  });

  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final active = selected || isHighlight;
    return SpringTap(
      onTap: onTap,
      child: Material(
        color: selected ? palette.accent : palette.paper,
        borderRadius: BorderRadius.circular(18),
        elevation: palette.isHalloween ? 1 : 0.4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? palette.accentText
                    : (active ? palette.ink : palette.inkSoft),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.paperRaised,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? palette.ink
                : palette.inkSoft.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
