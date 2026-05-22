import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/features/feed/data/job_interactions_provider.dart';
import 'package:jobswipe/features/feed/presentation/widgets/job_info_overlay.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class TikTokVideoCard extends ConsumerStatefulWidget {
  final JobOffer job;

  const TikTokVideoCard({super.key, required this.job});

  @override
  ConsumerState<TikTokVideoCard> createState() => _TikTokVideoCardState();
}

class _TikTokVideoCardState extends ConsumerState<TikTokVideoCard> {
  VideoPlayerController? _controller;
  Timer? _viewTimer;

  bool _viewRegistered = false;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isVisible = false;
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _initializeVideoIfNeeded() async {
    if (_controller != null || _isLoading) return;

    if (widget.job.videoUrl.trim().isEmpty) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.job.videoUrl),
      );

      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_isMuted ? 0 : 1);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      if (_isVisible) {
        await controller.play();
        _startViewTimer();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _startViewTimer() {
    if (_viewRegistered) return;

    _viewTimer?.cancel();

    _viewTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted || _viewRegistered || !_isVisible) return;

      _viewRegistered = true;

      await ref
          .read(jobInteractionsServiceProvider)
          .registerView(widget.job.id);
    });
  }

  void _cancelViewTimer() {
    _viewTimer?.cancel();
  }

  Future<void> _disposeVideo() async {
    final controller = _controller;

    if (controller == null) return;

    _cancelViewTimer();

    await controller.pause();
    await controller.dispose();

    if (!mounted) return;

    setState(() {
      _controller = null;
      _isInitialized = false;
      _isLoading = false;
    });
  }

  Future<void> _handleVisibility(double visibleFraction) async {
    final shouldBeVisible = visibleFraction > 0.70;

    if (shouldBeVisible && !_isVisible) {
      _isVisible = true;

      await _initializeVideoIfNeeded();

      if (_controller != null && _isInitialized) {
        await _controller!.play();
        _startViewTimer();
      }

      return;
    }

    if (!shouldBeVisible && _isVisible) {
      _isVisible = false;

      _cancelViewTimer();

      if (_controller != null) {
        await _controller!.pause();
      }

      if (visibleFraction < 0.10) {
        await _disposeVideo();
      }
    }
  }

  void _toggleMute() {
    final controller = _controller;

    setState(() {
      _isMuted = !_isMuted;
    });

    if (controller != null) {
      controller.setVolume(_isMuted ? 0 : 1);
    }
  }

  @override
  void dispose() {
    _cancelViewTimer();
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
            _VideoLoadingPlaceholder(thumbnailUrl: widget.job.thumbnailUrl),

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

class _VideoLoadingPlaceholder extends StatelessWidget {
  final String thumbnailUrl;

  const _VideoLoadingPlaceholder({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFF020713),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(color: const Color(0xFF020713));
          },
        ),
        Container(color: Colors.black.withOpacity(0.25)),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
