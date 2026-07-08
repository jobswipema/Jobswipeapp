import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CandidateVideoCvPlayerPage extends StatefulWidget {
  final String candidateName;
  final String jobTitle;
  final String videoCvUrl;
  final String videoCvThumbnailUrl;
  final String candidateBio;
  final String candidateSkills;

  const CandidateVideoCvPlayerPage({
    super.key,
    required this.candidateName,
    required this.jobTitle,
    required this.videoCvUrl,
    required this.videoCvThumbnailUrl,
    required this.candidateBio,
    required this.candidateSkills,
  });

  @override
  State<CandidateVideoCvPlayerPage> createState() =>
      _CandidateVideoCvPlayerPageState();
}

class _CandidateVideoCvPlayerPageState
    extends State<CandidateVideoCvPlayerPage> {
  late final VideoPlayerController _controller;

  bool _isInitialized = false;
  bool _isMuted = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoCvUrl),
      );

      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(1);
      await _controller.play();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    if (!_isInitialized) return;

    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    if (_isInitialized || !_hasError) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidateName = widget.candidateName.trim().isEmpty
        ? 'Candidat'
        : widget.candidateName.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF020713),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildVideoArea()),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.78),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _CandidateVideoOverlay(
                candidateName: candidateName,
                jobTitle: widget.jobTitle,
                candidateBio: widget.candidateBio,
                candidateSkills: widget.candidateSkills,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_hasError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Impossible de charger le CV vidéo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      if (widget.videoCvThumbnailUrl.trim().isNotEmpty) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.videoCvThumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(color: const Color(0xFF020713));
              },
            ),
            Container(color: Colors.black.withOpacity(0.35)),
            const Center(child: CircularProgressIndicator()),
          ],
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

class _CandidateVideoOverlay extends StatelessWidget {
  final String candidateName;
  final String jobTitle;
  final String candidateBio;
  final String candidateSkills;

  const _CandidateVideoOverlay({
    required this.candidateName,
    required this.jobTitle,
    required this.candidateBio,
    required this.candidateSkills,
  });

  @override
  Widget build(BuildContext context) {
    final cleanBio = candidateBio.trim();
    final cleanSkills = candidateSkills.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          candidateName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        if (jobTitle.trim().isNotEmpty)
          Text(
            jobTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (cleanBio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            cleanBio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
        if (cleanSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            cleanSkills,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.blueAccent.shade100,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
