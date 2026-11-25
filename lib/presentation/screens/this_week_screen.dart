import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../../domain/models/week_card.dart';
import '../../domain/pregnancy.dart';
import '../widgets/nursery_stage.dart';

/// This Week tab — browse gestational weeks 4–42 with approved baby-voice cards.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  List<WeekCard>? _cards;
  late int _selectedWeek;

  static const int _minWeek = AppConstants.minWeek; // 4
  static const int _maxWeek = AppConstants.maxWeek; // 42

  @override
  void initState() {
    super.initState();
    _selectedWeek = _currentWeek();
    _loadCards();
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
    if (mounted) {
      setState(() => _cards = WeekCard.listFromJsonString(raw));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final cards = _cards;

    if (cards == null) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    final mode = palette.isHalloween ? 'halloween' : 'everyday';
    final card = WeekCard.findFor(
      cards: cards,
      week: _selectedWeek,
      mode: mode,
    );

    return Column(
      children: [
        const SizedBox(height: 16),

        // Week dot strip
        _WeekDots(
          selected: _selectedWeek,
          min: _minWeek,
          max: _maxWeek,
          current: _currentWeek(),
          palette: palette,
        ),
        const SizedBox(height: 16),

        // Card + arrows
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Expanded(
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
                          widget.state.costumeOverride ??
                          widget.state.todayNeed,
                      isCurrentWeek: _selectedWeek == _currentWeek(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavButton(
                      icon: Icons.arrow_back_ios_new,
                      label: 'Previous week',
                      enabled: _selectedWeek > _minWeek,
                      palette: palette,
                      onTap: () => setState(() => _selectedWeek--),
                    ),
                    Text(
                      'Week $_selectedWeek',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.moonlight,
                      ),
                    ),
                    _NavButton(
                      icon: Icons.arrow_forward_ios,
                      label: 'Next week',
                      enabled: _selectedWeek < _maxWeek,
                      palette: palette,
                      onTap: () => setState(() => _selectedWeek++),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WeekDots extends StatelessWidget {
  const _WeekDots({
    required this.selected,
    required this.min,
    required this.max,
    required this.current,
    required this.palette,
  });

  final int selected;
  final int min;
  final int max;
  final int current;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(max - min + 1, (i) {
          final week = min + i;
          final isSelected = week == selected;
          final isCurrent = week == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: isSelected ? 10 : 5,
            height: isSelected ? 10 : 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? palette.accent
                  : isCurrent
                  ? palette.moon.withValues(alpha: 0.6)
                  : palette.moonlightSoft.withValues(alpha: 0.25),
            ),
          );
        }),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(28),
        border: isCurrentWeek
            ? Border.all(color: palette.accent.withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isHalloween ? 0.3 : 0.06,
            ),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NurseryStage(
              need: avatarNeed,
              tone: tone,
              expression: isCurrentWeek ? 'big-smile' : 'calm',
              height: 152,
              avatarSize: 122,
              topLeftBadge: isCurrentWeek
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(12),
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
            ),
            const SizedBox(height: 14),
            Text(
              'Week $week',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: palette.moon,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card?.babyLine ?? 'Week $week is on the way.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: palette.ink,
              ),
              textAlign: TextAlign.center,
            ),
            if (card?.sizeObject != null) ...[
              const SizedBox(height: 12),
              Text(
                '📏 About the size of a ${card!.sizeObject}',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.inkSoft,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? palette.paperRaised.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? palette.moonlight
                : palette.moonlightSoft.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
