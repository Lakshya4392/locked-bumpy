import 'package:flutter/material.dart';
import '../widgets/pause_button.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/week_card.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/nursery_scene.dart';

/// This Week tab — browse gestational weeks 4–42 with approved baby-voice cards.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  List<WeekCard>? _cards;
  static const int _minWeek = AppConstants.minWeek;
  static const int _maxWeek = AppConstants.maxWeek;
  late int _currentWeek;
  late int _selectedWeek;
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.state.currentWeek ?? _minWeek;
    _selectedWeek = _currentWeek;
    _pages = PageController(initialPage: _selectedWeek - _minWeek);
    _loadCards();
  }

  @override
  void didUpdateWidget(ThisWeekScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.state.currentWeek ?? _minWeek;
    if (current == _currentWeek) return;
    final following = _selectedWeek == _currentWeek;
    _currentWeek = current;
    if (following) {
      _selectedWeek = current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(current - _minWeek);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int week) {
    final index = week - _minWeek;
    if (MediaQuery.disableAnimationsOf(context) ||
        (_selectedWeek - week).abs() > 1) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _chooseWeek() async {
    final palette = AppPalette.of(context);
    final selected = _selectedWeek;
    final selectedKey = GlobalKey();
    var positioned = false;
    final week = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.paper,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      constraints: const BoxConstraints(maxWidth: 440),
      builder: (sheet) {
        if (!positioned) {
          positioned = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final anchor = selectedKey.currentContext;
            if (anchor != null) {
              Scrollable.ensureVisible(anchor, alignment: .45);
            }
          });
        }
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheet).height * .73,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Choose a week',
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      PauseButton(
                        onPressed: widget.state.pause,
                        color: palette.ink,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheet),
                        tooltip: 'Close',
                        icon: Icon(Icons.close, color: palette.ink),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var n = _minWeek; n <= _maxWeek; n++)
                          Semantics(
                            key: n == selected ? selectedKey : null,
                            label: n == _currentWeek
                                ? 'Week $n, current week'
                                : 'Week $n',
                            selected: n == selected,
                            button: true,
                            excludeSemantics: true,
                            onTap: () => Navigator.pop(sheet, n),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(54, 48),
                                foregroundColor: n == selected
                                    ? palette.accentText
                                    : palette.ink,
                                backgroundColor: n == selected
                                    ? palette.accent
                                    : palette.paperRaised,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: n == _currentWeek
                                      ? BorderSide(
                                          color: palette.accent,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                              ),
                              onPressed: () => Navigator.pop(sheet, n),
                              child: Text('$n'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted && week != null) _goTo(week);
  }

  Future<void> _loadCards() async {
    final cards = await ContentLoader.loadWeekCards();
    if (mounted) setState(() => _cards = cards);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final cards = _cards;

    if (cards == null) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    final mode = palette.isHalloween ? 'halloween' : 'everyday';
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _maxWeek - _minWeek + 1,
            onPageChanged: (page) =>
                setState(() => _selectedWeek = page + _minWeek),
            itemBuilder: (context, index) {
              final week = _minWeek + index;
              final card = WeekCard.findFor(
                cards: cards,
                week: week,
                mode: mode,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomScrollView(
                  key: PageStorageKey('week-$week'),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _WeekCardView(
                        onReturn: () => _goTo(_currentWeek),
                        portrait: week == _currentWeek
                            ? BumpyAvatar(
                                need:
                                    widget.state.costumeOverride ??
                                    widget.state.todayNeed,
                                palette: palette,
                                happy: false,
                                skinTone: widget.state.skinTone,
                              )
                            : null,
                        week: week,
                        card: card,
                        palette: palette,
                        isCurrentWeek: week == _currentWeek,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.arrow_back_ios_new,
                label: 'Previous week',
                enabled: _selectedWeek > _minWeek,
                palette: palette,
                onTap: () => _goTo(_selectedWeek - 1),
              ),
              Flexible(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: palette.moonlight,
                  ),
                  onPressed: _chooseWeek,
                  child: const Text('Choose week', textAlign: TextAlign.center),
                ),
              ),
              _NavButton(
                icon: Icons.arrow_forward_ios,
                label: 'Next week',
                enabled: _selectedWeek < _maxWeek,
                palette: palette,
                onTap: () => _goTo(_selectedWeek + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WeekCardView extends StatelessWidget {
  const _WeekCardView({
    required this.week,
    required this.card,
    required this.palette,
    required this.isCurrentWeek,
    required this.portrait,
    required this.onReturn,
  });

  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final bool isCurrentWeek;
  final BumpyAvatar? portrait;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final beside =
        size.width >= 540 &&
        size.height <= 600 &&
        MediaQuery.textScalerOf(context).scale(14) <= 21;
    final short = beside && size.height < 380;
    final avatar = portrait;
    final room = avatar == null
        ? null
        : NurseryScene(
            palette: palette,
            avatar: avatar,
            height: beside ? (short ? 112 : 150) : 192,
          );
    final text = Padding(
      padding: short
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isCurrentWeek) ...[
                Image.asset(
                  'assets/images/need-rest.png',
                  width: 34,
                  height: 34,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Week $week',
                        style: TextStyle(
                          fontSize: short ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: palette.accent,
                        ),
                      ),
                    ),
                    if (isCurrentWeek)
                      Text(
                        'You are here',
                        style: TextStyle(
                          color: palette.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (card != null) ...[
            SizedBox(height: short ? 5 : 10),
            Text(
              card!.babyLine,
              style: TextStyle(
                fontSize: short ? 16 : 18,
                height: short ? 1.3 : 1.45,
                color: palette.ink,
              ),
            ),
          ],
          if (!isCurrentWeek) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to this week'),
              onPressed: onReturn,
            ),
          ],
        ],
      ),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: palette.paper,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: room != null && beside
              ? Row(
                  children: [
                    Expanded(flex: short ? 1 : 2, child: room),
                    Expanded(flex: short ? 2 : 3, child: text),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [?room, text],
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
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: palette.moonlight,
          disabledForegroundColor: palette.moonlightSoft.withValues(
            alpha: 0.45,
          ),
          // Both looks use a dark sky outside the paper card.
          backgroundColor: palette.moonlight.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, semanticLabel: label, size: 20),
      ),
    );
  }
}
