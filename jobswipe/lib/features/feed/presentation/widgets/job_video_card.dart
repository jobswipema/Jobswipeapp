import 'package:flutter/material.dart';
import 'package:jobswipe/features/feed/presentation/widgets/feed_actions_column.dart';
import 'package:jobswipe/features/feed/presentation/widgets/job_info_overlay.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class JobVideoCard extends StatelessWidget {
  final JobOffer job;

  const JobVideoCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF020617), Color(0xFF071226), Color(0xFF0B1220)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: JobInfoOverlay(job: job),
        ),
        const Align(
          alignment: Alignment.centerRight,
          child: FeedActionsColumn(
            likes: '23.5K',
            saves: '1.1K',
            applies: '212',
          ),
        ),
      ],
    );
  }
}
