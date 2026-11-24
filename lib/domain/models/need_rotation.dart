import '../../core/constants/app_constants.dart';
import 'need.dart';

/// Deterministic daily rotation through the 6 maternal needs.
///
/// Order: IRON → BRAIN → BONES → WATER → REST → VITAMIN → repeat.
/// The epoch is [AppConstants.rotationEpoch] (2026-11-23 = day 0 = IRON).
/// No randomness, no network — identical result on every device for the same date.
class NeedRotation {
  NeedRotation._();

  static const List<MaternalNeed> _order = [
    MaternalNeed.iron,
    MaternalNeed.brain,
    MaternalNeed.bones,
    MaternalNeed.water,
    MaternalNeed.rest,
    MaternalNeed.vitamin,
  ];

  /// Returns the [MaternalNeed] for [date].
  static MaternalNeed forDate(DateTime date) {
    final epoch = AppConstants.rotationEpoch;
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final normalizedEpoch = DateTime.utc(epoch.year, epoch.month, epoch.day);
    final dayOffset = normalizedDate.difference(normalizedEpoch).inDays;
    // Positive modulo to handle dates before epoch.
    final index = dayOffset % _order.length;
    return _order[index < 0 ? index + _order.length : index];
  }

  /// Water and Vitamin are check-ins themselves, so when today's need is one
  /// of those the third slot becomes REST instead (spec req).
  static MaternalNeed thirdCheckIn(MaternalNeed todayNeed) {
    if (todayNeed == MaternalNeed.water || todayNeed == MaternalNeed.vitamin) {
      return MaternalNeed.rest;
    }
    return todayNeed;
  }

  /// Keep the day's featured need first, with each action shown exactly once.
  static List<MaternalNeed> checkIns(MaternalNeed today) => [
    today,
    for (final other in [
      MaternalNeed.water,
      MaternalNeed.vitamin,
      thirdCheckIn(today),
    ])
      if (other != today) other,
  ];
}
