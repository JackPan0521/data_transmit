import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../utils/timeline_utils.dart';

class TimelineView extends StatelessWidget {
  final List<ScheduleModel> scheduleList;
  final ScrollController scrollController;
  final DateTime selectedDate;
  final VoidCallback onScheduleUpdated;

  const TimelineView({
    super.key,
    required this.scheduleList,
    required this.scrollController,
    required this.selectedDate,
    required this.onScheduleUpdated,
  });

  @override
  Widget build(BuildContext context) {
    const double hourHeight = 80.0;
    const double timelineWidth = 80.0;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 24 * hourHeight,
            child: Stack(
              children: [
                TimelineUtils.buildTimeGrid(hourHeight, timelineWidth),
                ...TimelineUtils.buildContinuousScheduleBars(
                  scheduleList,
                  hourHeight,
                  timelineWidth,
                  context,
                  selectedDate,
                  onScheduleUpdated,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
