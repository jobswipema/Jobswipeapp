import 'package:flutter/material.dart';
import 'package:jobswipe/features/feed/presentation/widgets/job_info_overlay.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:video_player/video_player.dart';

class TikTokVideoCard extends StatefulWidget {
  final JobOffer job;

  const TikTokVideoCard({super.key, required this.job});

  @override
  State<TikTokVideoCard> createState() => _TikTokVideoCardState();
}

class _TikTokVideoCardState extends State<TikTokVideoCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.job.videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.job.videoUrl),
    );

    _controller = controller;

    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0);
    await controller.play();

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _isMuted = !_isMuted;
    });

    controller.setVolume(_isMuted ? 0 : 1);
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller != null && _isInitialized)
          GestureDetector(
            onTap: _toggleMute,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          )
        else
          Container(
            color: const Color(0xFF020713),
            child: const Center(child: CircularProgressIndicator()),
          ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.10),
                Colors.black.withOpacity(0.75),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        Positioned(
          right: 18,
          top: 80,
          child: IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),

        JobInfoOverlay(job: widget.job),
      ],
    );
  }
}
