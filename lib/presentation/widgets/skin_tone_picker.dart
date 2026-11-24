import 'package:flutter/material.dart';
import '../../domain/models/skin_tone.dart';
import 'paper_portrait.dart';

class SkinTonePicker extends StatelessWidget {
  const SkinTonePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.foreground,
    this.showPreview = false,
  });
  final SkinTone selected;
  final ValueChanged<SkinTone> onSelected;
  final Color foreground;
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(
        'Bumpy’s skin tone',
        style: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview)
          Row(
            children: [
              SizedBox.square(
                dimension: 80,
                child: ClipOval(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 118,
                    maxHeight: 118,
                    minWidth: 118,
                    maxWidth: 118,
                    child: Image(
                      key: const ValueKey('skin-tone-preview'),
                      image: paperPortrait(
                        'assets/images/everyday.png',
                        selected,
                      ),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: heading),
            ],
          )
        else
          heading,
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final tone in SkinTone.values)
              ChoiceChip(
                avatar: CircleAvatar(
                  backgroundColor: Color(0xff000000 | tone.rgb),
                ),
                label: Text(tone.label),
                selected: selected == tone,
                onSelected: (_) => onSelected(tone),
              ),
          ],
        ),
      ],
    );
  }
}
