import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../widgets/baby_avatar.dart';

/// Bottom sheet allowing the mother to try on any of the 6 Halloween costumes
/// without altering today's maternal need or check-in tiles.
class ClosetSheet extends StatelessWidget {
  const ClosetSheet({super.key, required this.state});

  final AppState state;

  static Future<void> show(BuildContext context, AppState state) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClosetSheet(state: state),
    );
  }

  String _outfitTitle(MaternalNeed need, AppPalette palette) {
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

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final activeCostume = state.costumeOverride ?? state.todayNeed;

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.inkSoft.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        palette.isHalloween
                            ? 'Costume Closet'
                            : 'Outfit Closet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: palette.ink,
                        ),
                      ),
                      if (state.costumeOverride != null)
                        TextButton(
                          onPressed: () {
                            state.setCostumeOverride(null);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Reset to today's",
                            style: TextStyle(
                              color: palette.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Try on any outfit. Your daily check-ins stay the same.',
                      style: TextStyle(fontSize: 13, color: palette.inkSoft),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                    children: MaternalNeed.values.map((need) {
                      final isSelected = activeCostume == need;
                      final costumeTitle = _outfitTitle(need, palette);
                      return Semantics(
                        label: '$costumeTitle costume for ${need.needName}',
                        selected: isSelected,
                        button: true,
                        child: InkWell(
                          onTap: () {
                            state.setCostumeOverride(need);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.paperRaised,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? need.color
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: BabyAvatar(
                                    need: need,
                                    tone: state.babyTone,
                                    expression: 'big-smile',
                                    size: 68,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  costumeTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: palette.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  need.needName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: palette.inkSoft,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
