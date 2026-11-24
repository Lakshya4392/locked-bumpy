import 'package:flutter/material.dart';
import 'pause_button.dart';

Future<DateTime?> pickPregnancyDate(
  BuildContext context, {
  required DateTime today,
  required bool useDueDate,
  required VoidCallback onPause,
  DateTime? selected,
}) {
  DateTime offset(int days) =>
      DateTime(today.year, today.month, today.day + days);
  final first = offset(useDueDate ? -7 : -294);
  final last = offset(useDueDate ? 294 : 0);
  final candidate = selected ?? offset(useDueDate ? 140 : -140);
  // Older saves may fall outside the interval offered for a new choice.
  final initial = candidate.isBefore(first)
      ? first
      : candidate.isAfter(last)
      ? last
      : candidate;
  return showDialog<DateTime>(
    context: context,
    builder: (dialog) {
      final size = MediaQuery.sizeOf(dialog);
      final short = size.width > size.height && size.height < 480;
      final calendar = DatePickerDialog(
        currentDate: today,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        helpText: useDueDate
            ? 'Pick your due date'
            : 'Pick your last period start',
        insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
      final pause = Material(
        color: Theme.of(dialog).colorScheme.surface,
        shape: const CircleBorder(),
        child: PauseButton(
          onPressed: onPause,
          color: Theme.of(dialog).colorScheme.onSurface,
        ),
      );
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: short ? 640 : 420),
          child: short
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: calendar),
                    pause,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(alignment: Alignment.centerRight, child: pause),
                    Flexible(child: calendar),
                  ],
                ),
        ),
      );
    },
  );
}
