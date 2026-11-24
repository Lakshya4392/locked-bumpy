import 'package:flutter/material.dart';
import '../widgets/pause_button.dart';
import '../widgets/paper_choice.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/paper_portrait.dart';

class ClosetSheet extends StatefulWidget {
  const ClosetSheet({super.key, required this.state});
  final AppState state;

  static Future<void> open(BuildContext context, AppState state) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 440),
      backgroundColor: AppPalette.of(context).paper,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => ClosetSheet(state: state),
    );
  }

  @override
  State<ClosetSheet> createState() => _ClosetSheetState();
}

class _ClosetSheetState extends State<ClosetSheet> {
  late MaternalNeed _preview;

  @override
  void initState() {
    super.initState();
    _preview = widget.state.costumeOverride ?? widget.state.todayNeed;
    widget.state.addListener(_onChange);
  }

  bool get _available =>
      widget.state.isHalloween &&
      !widget.state.isPaused &&
      !widget.state.isFirstRun;

  void _onChange() {
    if (!_available && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    final state = widget.state;
    final palette = AppPalette.of(context);
    final name = _costumeName(_preview);
    final size = MediaQuery.sizeOf(context);
    final shortPhone = size.width <= 375 && size.height <= 600;
    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Tonight’s wardrobe',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.ink,
              ),
            ),
          ),
        ),
        PauseButton(onPressed: state.pause, color: palette.ink),
        IconButton(
          tooltip: 'Close wardrobe',
          icon: Icon(Icons.close, color: palette.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
    final rail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.paperRaised,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: BumpyAvatar(
              need: _preview,
              palette: palette,
              skinTone: state.skinTone,
              happy: state.isChecked(state.todayNeed.name),
            ),
          ),
        ),
        SizedBox(height: shortPhone ? 6 : 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                (constraints.maxWidth >= 320 ||
                        (constraints.maxWidth >= 282 &&
                            MediaQuery.textScalerOf(context).scale(14) <=
                                17)) &&
                    MediaQuery.textScalerOf(context).scale(14) <= 21
                ? 3
                : 2;
            return Wrap(
              spacing: 8,
              runSpacing: shortPhone ? 4 : 8,
              children: [
                for (final need in MaternalNeed.values)
                  SizedBox(
                    width: (constraints.maxWidth - 8 * (columns - 1)) / columns,
                    child: _CostumeCard(
                      thumbnailSize: shortPhone ? 48 : 65,
                      need: need,
                      skinTone: state.skinTone,
                      palette: palette,
                      selected: _preview == need,
                      onTap: () => setState(() => _preview = need),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
    final footer = Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Wear it for this visit. Today’s check-in stays the same.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.inkSoft),
          ),
          const SizedBox(height: 6),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.ink,
              foregroundColor: palette.paper,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () {
              state.setCostumeOverride(_preview);
              Navigator.of(context).pop();
            },
            child: Text('Wear $name'),
          ),
        ],
      ),
    );
    final compact =
        MediaQuery.sizeOf(context).height < 450 ||
        MediaQuery.textScalerOf(context).scale(14) > 21;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: compact
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header, rail, footer],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Flexible(child: SingleChildScrollView(child: rail)),
                  footer,
                ],
              ),
      ),
    );
  }
}

String _costumeName(MaternalNeed need) =>
    need.costume[0] + need.costume.substring(1).toLowerCase();

class _CostumeCard extends StatelessWidget {
  const _CostumeCard({
    required this.thumbnailSize,
    required this.need,
    required this.palette,
    required this.selected,
    required this.skinTone,
    required this.onTap,
  });
  final double thumbnailSize;
  final MaternalNeed need;
  final AppPalette palette;
  final bool selected;
  final SkinTone skinTone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _costumeName(need);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? palette.accent : Colors.transparent,
        width: 2,
      ),
    );
    return Material(
      color: palette.paperRaised,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: PaperChoice(
        key: ValueKey('closet-${need.name}'),
        selected: selected,
        label: 'Try $name, ${need.label}',
        onTap: onTap,
        focusColor: palette.ink,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: thumbnailSize,
              child: ColoredBox(
                color: Color.alphaBlend(
                  palette.moonlight.withValues(alpha: .40),
                  palette.paperRaised,
                ),
                child: Center(
                  child: Image(
                    image: paperPortrait(need.assetPath(palette), skinTone),
                    height: thumbnailSize - 2,
                    width: thumbnailSize - 2,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 3,
                children: [
                  if (selected) Icon(Icons.check, size: 14, color: palette.ink),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: palette.ink,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                need.label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
