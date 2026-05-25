import 'package:flutter/material.dart';
import 'package:jobswipe/features/feed/presentation/widgets/tiktok_video_card.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class SingleJobVideoPage extends StatelessWidget {
  final JobOffer job;

  const SingleJobVideoPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          TikTokVideoCard(job: job),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
