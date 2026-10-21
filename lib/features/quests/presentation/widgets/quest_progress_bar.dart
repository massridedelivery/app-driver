import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/quests/domain/entities/driver_quest.dart';

/// Card surface shared with the job cards: dark #262932, light white.
Color questSurface(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF262932)
    : Colors.white;

/// What sits under each step mark.
enum QuestBarLabel { trips, cumulative, none }

/// The quest bar: filled to current_count / target_count, a mark at each
/// step's trips / target_count, reached steps in [color], with the step's
/// trips (or cumulative reward) under its mark.
class QuestProgressBar extends StatelessWidget {
  const QuestProgressBar({
    super.key,
    required this.quest,
    required this.color,
    this.gradient,
    this.labels = QuestBarLabel.trips,
    this.height = 8,
  });

  final DriverQuest quest;
  final Color color;

  /// Optional fill gradient (the profile card's orange bar).
  final Gradient? gradient;
  final QuestBarLabel labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Light track on both themes; unreached marks cut the bar in the card's
    // own colour.
    final track = Theme.of(context).brightness == Brightness.dark
        ? const Color(0x24FFFFFF)
        : const Color(0xFFE2E8F0);
    final cut = questSurface(context);
    final idle = context.palette.textSecondary;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height + 6,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 3,
                    height: height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: track,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 3,
                    height: height,
                    width: w * quest.progress,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: gradient == null ? color : null,
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  ),
                  for (final m in quest.milestones)
                    Positioned(
                      left: (w * quest.stepAt(m) - 1.5).clamp(0.0, w - 3),
                      top: 0,
                      width: 3,
                      height: height + 6,
                      child: ColoredBox(color: m.reached ? color : cut),
                    ),
                ],
              ),
            ),
            if (labels != QuestBarLabel.none)
              SizedBox(
                height: 18,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final m in quest.milestones)
                      Positioned(
                        // Right-aligned to the mark so the last label stays
                        // inside the card.
                        right: (w - w * quest.stepAt(m)).clamp(0.0, w),
                        top: 3,
                        child: Text(
                          labels == QuestBarLabel.trips
                              ? '${m.trips}'
                              : formatBaht(m.cumulative),
                          style: AppTypography.caption5.copyWith(
                            color: m.reached ? color : idle,
                            fontWeight: m.reached
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
