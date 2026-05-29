import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivered_status_banner.dart';

class DeliveredTimeline extends StatelessWidget {
  const DeliveredTimeline({
    super.key,
    required this.events,
    this.compact = false,
  });

  final List<DeliveredTimelineEvent> events;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          for (var index = 0; index < events.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: index == 0
                            ? const SizedBox()
                            : Container(height: 2, color: deliveredGreen),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: deliveredGreen,
                      ),
                      Expanded(
                        child: index == events.length - 1
                            ? const SizedBox()
                            : Container(height: 2, color: deliveredGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    events[index].title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var index = 0; index < events.length; index++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: deliveredGreen,
                        size: 17,
                      ),
                      if (index < events.length - 1)
                        Expanded(
                          child: Container(width: 2, color: deliveredGreenSoft),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index < events.length - 1 ? 15 : 0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            events[index].title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          events[index].time,
                          style: const TextStyle(
                            color: deliveredGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
