import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/content_record.dart';
import '../../domain/models/need.dart';
import '../sheets/closet_sheet.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/nursery_scene.dart';
import '../widgets/visit_topics.dart';

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
  DateTime? _reviewingDay;
  bool _savingTopic = false;
  MaternalNeed? _failedTopic;

  Future<void> _saveForVisit(MaternalNeed need) async {
    if (_savingTopic) return;
    setState(() {
      _savingTopic = true;
      _failedTopic = null;
    });
    try {
      await widget.state.saveVisitTopics({...widget.state.visitTopics, need});
    } catch (_) {
      if (mounted) setState(() => _failedTopic = need);
    } finally {
      if (mounted) setState(() => _savingTopic = false);
    }
  }

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

    if (mounted &&
        id == widget.state.todayNeed.name &&
        widget.state.isChecked(id) &&
        !wasChecked &&
        !_hopping &&
        !MediaQuery.disableAnimationsOf(context)) {
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
    final records = _records;
    if (records == null) return '';
    return ContentLoader.find(
          records: records,
          need: allDone ? 'ALL' : need.needName,
          category: allDone
              ? 'goodbye'
              : needTicked
              ? 'thank_you'
              : 'greeting',
          mode:
              palette.isHalloween &&
                  (widget.state.costumeOverride ?? need) == need
              ? 'halloween'
              : 'everyday',
        )?.text ??
        '';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = widget.state;
    final need = state.todayNeed;
    final needTicked = state.isChecked(need.name);
    final allDone =
        state.allChecked && state.checkInStatus == CheckInSaveStatus.saved;
    final checkIns = state.dailyCheckIns;
    final reviewing = DateUtils.isSameDay(_reviewingDay, state.today);
    final babyLine = _babyLine(need, needTicked, allDone, palette);
    final savedForVisit = state.visitTopics.contains(need);

    return LayoutBuilder(
      builder: (context, bounds) {
        final sideBySide = bounds.maxWidth >= 510;
        final nursery = Material(
          color: palette.paper,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NurseryScene(
                palette: palette,
                height: sideBySide ? 156 : 204,
                cornerAction: palette.isHalloween
                    ? Tooltip(
                        message: 'Costume closet',
                        child: FilledButton.tonalIcon(
                          onPressed: () => ClosetSheet.open(context, state),
                          icon: const Icon(Icons.checkroom, size: 18),
                          label: const Text('Wardrobe'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: palette.paper,
                            foregroundColor: palette.ink,
                          ),
                        ),
                      )
                    : null,
                avatar: BumpyAvatar(
                  need: state.costumeOverride ?? need,
                  palette: palette,
                  happy: needTicked,
                  skinTone: state.skinTone,
                  hopAnimation: _hopAnimation,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            state.babyDisplayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        Text(
                          state.costumeOverride != null && palette.isHalloween
                              ? 'TODAY · ${need.needName}'
                              : need.tag(palette),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: .5,
                            fontWeight: FontWeight.w600,
                            color: palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    if (babyLine.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          babyLine,
                          style: TextStyle(
                            fontSize: 21,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Semantics(
                      liveRegion: true,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.ink,
                          minimumSize: const Size(0, 48),
                        ),
                        icon:
                            Uri.base.queryParameters['visit-control'] == 'plain'
                            ? Icon(
                                savedForVisit
                                    ? Icons.bookmark
                                    : Icons.bookmark_add_outlined,
                                size: 28,
                              )
                            : CustomPaint(
                                size: const Size.square(28),
                                painter: _PaperPocket(palette, savedForVisit),
                              ),
                        label: Text(
                          savedForVisit
                              ? '${need.label} saved · View visit list'
                              : _savingTopic
                              ? 'Saving…'
                              : 'Save ${need.label} for my visit',
                        ),
                        onPressed: _savingTopic
                            ? null
                            : savedForVisit
                            ? () => VisitTopics.edit(context, state)
                            : () => _saveForVisit(need),
                      ),
                    ),
                    if (_failedTopic == need && !savedForVisit)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          'Couldn’t save to your visit list. Tap to try again.',
                          style: TextStyle(color: palette.ink),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        final checkInsPanel = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (allDone && !reviewing)
              _SavedCheckIns(
                needs: checkIns,
                palette: palette,
                onReview: () => setState(() => _reviewingDay = state.today),
                onWeek: () => state.setTab(1),
              )
            else
              Semantics(
                header: true,
                child: Text(
                  allDone ? 'Saved check-ins' : "Today's check-ins",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.moonlight,
                  ),
                ),
              ),
            if (state.completedCheckIns.isEmpty || (allDone && reviewing)) ...[
              const SizedBox(height: 3),
              Text(
                allDone
                    ? 'Tap a checked row to undo it.'
                    : 'Tap a row when you’ve done it.',
                style: TextStyle(color: palette.moonlightSoft, fontSize: 14),
              ),
            ],
            const SizedBox(height: 10),
            if (!allDone || reviewing)
              Material(
                color: palette.paperRaised,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final item in checkIns) ...[
                      if (item != checkIns.first)
                        Divider(
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                          color: palette.inkSoft.withValues(alpha: .22),
                        ),
                      _CheckInTile(
                        key: ValueKey(item),
                        title: item == need
                            ? '${need.needName} · Need of the Day'
                            : item.label,
                        subtitle: item.foodHint,
                        need: item,
                        isTicked: state.isChecked(item.name),
                        palette: palette,
                        onTap: () => _onCheckIn(item.name),
                      ),
                    ],
                  ],
                ),
              ),
            if (state.checkInStatus != CheckInSaveStatus.saved)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      Text(
                        state.checkInStatus == CheckInSaveStatus.saving
                            ? 'Saving check-ins…'
                            : 'Your check-ins couldn’t be saved on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.moonlight),
                      ),
                      if (state.checkInStatus == CheckInSaveStatus.failed)
                        TextButton(
                          onPressed: state.retryCheckIns,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: palette.moonlight,
                          ),
                          child: const Text('Retry save'),
                        ),
                    ],
                  ),
                ),
              ),
            if (allDone && reviewing)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: palette.moonlight),
                onPressed: () => setState(() => _reviewingDay = null),
                child: const Text('Back to summary'),
              ),
            const SizedBox(height: 8),
            Text(
              state.daysTogetherCount == 1
                  ? '1 day together'
                  : '${state.daysTogetherCount} days together',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.moonlightSoft, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(
              AppConstants.disclaimer,
              style: TextStyle(
                fontSize: 11,
                color: palette.moonlightSoft,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        );
        if (sideBySide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: nursery)),
                const SizedBox(width: 16),
                Expanded(child: SingleChildScrollView(child: checkInsPanel)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [nursery, const SizedBox(height: 20), checkInsPanel],
          ),
        );
      },
    );
  }
}

class _PaperPocket extends CustomPainter {
  const _PaperPocket(this.palette, this.saved);

  final AppPalette palette;
  final bool saved;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    final paint = Paint()..color = palette.inkSoft;
    canvas.drawPath(
      Path()
        ..moveTo(2, 8)
        ..lineTo(25, 6)
        ..lineTo(24, 19)
        ..lineTo(3, 21)
        ..close(),
      paint,
    );
    if (saved) {
      paint.color = palette.isHalloween
          ? const Color(0xffffeac5)
          : const Color(0xfffffae8);
      canvas.drawPath(
        Path()
          ..moveTo(7, 3)
          ..lineTo(20, 1)
          ..lineTo(22, 15)
          ..lineTo(9, 17)
          ..close(),
        paint,
      );
    }
    paint.color = palette.isHalloween
        ? const Color(0xffd7a4bc)
        : const Color(0xff90526e);
    canvas.drawPath(
      Path()
        ..moveTo(2, 9)
        ..lineTo(13, 14)
        ..lineTo(25, 7)
        ..lineTo(24, 21)
        ..lineTo(14, 26)
        ..lineTo(4, 22)
        ..close(),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PaperPocket old) =>
      old.saved != saved || old.palette != palette;
}

class _SavedCheckIns extends StatelessWidget {
  const _SavedCheckIns({
    required this.needs,
    required this.palette,
    required this.onReview,
    required this.onWeek,
  });
  final List<MaternalNeed> needs;
  final AppPalette palette;
  final VoidCallback onReview;
  final VoidCallback onWeek;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.paperRaised,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              children: [
                for (final need in needs)
                  Image.asset(
                    need.iconPath,
                    height: 26,
                    width: 26,
                    excludeFromSemantics: true,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                'Today’s check-ins are saved',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              needs.map((need) => need.label).join(' · '),
              style: TextStyle(color: palette.inkSoft, fontSize: 14),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.ink,
                side: BorderSide(color: palette.inkSoft),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onWeek,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text(
                'Open this week’s card',
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: palette.ink),
              onPressed: onReview,
              child: const Text('Review saved check-ins'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable check-in tile ─────────────────────────────────────────────────

class _CheckInTile extends StatelessWidget {
  const _CheckInTile({
    super.key,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Image.asset(
                need.iconPath,
                width: 32,
                height: 32,
                excludeFromSemantics: true,
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
                      style: TextStyle(fontSize: 14, color: palette.inkSoft),
                    ),
                  ],
                ),
              ),
              if (isTicked)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Done',
                      style: TextStyle(fontSize: 12, color: palette.ink),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
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
    );
  }
}
