import 'package:flutter/material.dart';
import 'package:jobswipe/features/feed/presentation/widgets/job_info_overlay.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class TikTokVideoCard extends StatefulWidget {
  final JobOffer job;

  const TikTokVideoCard({super.key, required this.job});

  @override
  State<TikTokVideoCard> createState() => _TikTokVideoCardState();
}

class _TikTokVideoCardState extends State<TikTokVideoCard> {
  VideoPlayerController? _controller;

  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isVisible = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.job.videoUrl.trim().isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.job.videoUrl),
      );

      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      await controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _handleVisibility(double visibleFraction) async {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    final shouldPlay = visibleFraction > 0.70;

    if (shouldPlay && !_isVisible) {
      _isVisible = true;
      await controller.play();
    }

    if (!shouldPlay && _isVisible) {
      _isVisible = false;
      await controller.pause();
    }
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

    return VisibilityDetector(
      key: Key('video_${widget.job.id}'),
      onVisibilityChanged: (info) {
        _handleVisibility(info.visibleFraction);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasError)
            Container(
              color: const Color(0xFF020713),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Impossible de charger la vidéo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          else if (controller != null && _isInitialized)
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
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.50),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned(
            right: 14,
            top: 70,
            child: SafeArea(
              child: IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 31,
                ),
              ),
            ),
          ),

          JobInfoOverlay(job: widget.job),
        ],
      ),
    );
  }
}
