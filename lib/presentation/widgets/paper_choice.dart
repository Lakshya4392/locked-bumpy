import 'package:flutter/material.dart';

/// A paper control with a visible keyboard focus ring and a single spoken label.
class PaperChoice extends StatefulWidget {
  const PaperChoice({
    super.key,
    required this.label,
    required this.onTap,
    required this.focusColor,
    required this.borderRadius,
    required this.child,
    this.selected,
    this.liveRegion = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color focusColor;
  final BorderRadius borderRadius;
  final Widget child;
  final bool? selected;
  final bool liveRegion;

  @override
  State<PaperChoice> createState() => PaperChoiceState();
}

class PaperChoiceState extends State<PaperChoice> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      selected: widget.selected,
      liveRegion: widget.liveRegion,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _focused = focused),
        borderRadius: widget.borderRadius,
        child: DecoratedBox(
          // Paint the ring over paper-colored cards and segment backgrounds.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: _focused
                ? Border.all(color: widget.focusColor, width: 3)
                : null,
          ),
          child: ExcludeSemantics(child: widget.child),
        ),
      ),
    );
  }
}
