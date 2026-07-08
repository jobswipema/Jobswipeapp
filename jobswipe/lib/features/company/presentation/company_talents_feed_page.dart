import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyTalentsFeedPage extends StatefulWidget {
  const CompanyTalentsFeedPage({super.key});

  @override
  State<CompanyTalentsFeedPage> createState() => _CompanyTalentsFeedPageState();
}

class _CompanyTalentsFeedPageState extends State<CompanyTalentsFeedPage> {
  int _currentIndex = 0;

  Stream<List<Map<String, dynamic>>> _talentsStream() {
    return FirebaseFirestore.instance
        .collection('talents')
        .where('isVisible', isEqualTo: true)
        .where('hasVideoCv', isEqualTo: true)
        .where('isOpenToWork', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final talents = snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();

          talents.sort((a, b) {
            final aDate = a['updatedAt'];
            final bDate = b['updatedAt'];

            if (aDate is! Timestamp && bDate is! Timestamp) return 0;
            if (aDate is! Timestamp) return 1;
            if (bDate is! Timestamp) return -1;

            return bDate.toDate().compareTo(aDate.toDate());
          });

          return talents;
        });
  }

  void _openTalentProfile(Map<String, dynamic> talent) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TalentProfileDetailsPage(talent: talent),
      ),
    );
  }

  Future<void> _openCv(Map<String, dynamic> talent) async {
    final cvUrl = talent['cvUrl']?.toString() ?? '';

    if (cvUrl.trim().isEmpty) return;

    await launchUrl(Uri.parse(cvUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020713),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _talentsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _TalentsEmptyState(
                icon: Icons.error_outline,
                title: 'Chargement impossible',
                message: 'Impossible de charger les talents pour le moment.',
                onBack: () => Navigator.of(context).pop(),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final talents = snapshot.data!;

            if (talents.isEmpty) {
              return _TalentsEmptyState(
                icon: Icons.video_library_outlined,
                title: 'Aucun talent visible',
                message:
                    'Les candidats Open to Work qui activent leur CV vidéo apparaîtront ici.',
                onBack: () => Navigator.of(context).pop(),
              );
            }

            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: talents.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final talent = talents[index];

                return _TalentVideoSlide(
                  talent: talent,
                  isActive: index == _currentIndex,
                  onOpenProfile: () => _openTalentProfile(talent),
                  onOpenCv: () => _openCv(talent),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TalentVideoSlide extends StatefulWidget {
  final Map<String, dynamic> talent;
  final bool isActive;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCv;

  const _TalentVideoSlide({
    required this.talent,
    required this.isActive,
    required this.onOpenProfile,
    required this.onOpenCv,
  });

  @override
  State<_TalentVideoSlide> createState() => _TalentVideoSlideState();
}

class _TalentVideoSlideState extends State<_TalentVideoSlide> {
  VideoPlayerController? _controller;

  bool _isInitialized = false;
  bool _isMuted = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoUrl = widget.talent['videoCvUrl']?.toString() ?? '';

    if (videoUrl.trim().isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);

      if (widget.isActive) {
        await controller.play();
      }

      if (!mounted) return;

      setState(() => _isInitialized = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(covariant _TalentVideoSlide oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controller = _controller;

    if (controller == null || !_isInitialized) return;

    if (widget.isActive && !oldWidget.isActive) {
      controller.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      controller.pause();
    }
  }

  void _togglePlayPause() {
    final controller = _controller;

    if (controller == null || !_isInitialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleMute() {
    final controller = _controller;

    if (controller == null || !_isInitialized) return;

    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        widget.talent['displayName']?.toString().trim().isNotEmpty == true
        ? widget.talent['displayName'].toString()
        : 'Candidat';

    final title = widget.talent['title']?.toString() ?? '';
    final city = widget.talent['city']?.toString() ?? '';
    final bio = widget.talent['bio']?.toString() ?? '';
    final cvUrl = widget.talent['cvUrl']?.toString() ?? '';

    final skills = widget.talent['skills'] is List
        ? (widget.talent['skills'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideoBackground(),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.28),
                Colors.transparent,
                Colors.black.withOpacity(0.86),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        Positioned(
          top: 8,
          left: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
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
          top: 62,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.48)),
            ),
            child: const Text(
              'OPEN TO WORK',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),

        Center(
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _showPlayIcon ? 1 : 0,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 7),
              if (title.trim().isNotEmpty)
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.84),
                  ),
                ),
              if (city.trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.white.withOpacity(0.74),
                      size: 19,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.74),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (bio.trim().isNotEmpty) ...[
                const SizedBox(height: 13),
                Text(
                  bio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: skills.take(5).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.45),
                        ),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: widget.onOpenProfile,
                        icon: const Icon(Icons.person_search_outlined),
                        label: const Text('Profil'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: cvUrl.trim().isNotEmpty
                            ? widget.onOpenCv
                            : null,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('CV PDF'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _showPlayIcon {
    final controller = _controller;

    if (!_isInitialized || controller == null) return true;

    return !controller.value.isPlaying;
  }

  Widget _buildVideoBackground() {
    if (_hasError) {
      return Container(
        color: const Color(0xFF020713),
        child: const Center(
          child: Text(
            'Impossible de lire cette vidéo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      final thumbnailUrl =
          widget.talent['videoCvThumbnailUrl']?.toString() ?? '';

      if (thumbnailUrl.trim().isNotEmpty) {
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
            Container(color: Colors.black.withOpacity(0.35)),
            const Center(child: CircularProgressIndicator()),
          ],
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    final controller = _controller!;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class TalentProfileDetailsPage extends StatelessWidget {
  final Map<String, dynamic> talent;

  const TalentProfileDetailsPage({super.key, required this.talent});

  Future<void> _openCv() async {
    final cvUrl = talent['cvUrl']?.toString() ?? '';

    if (cvUrl.trim().isEmpty) return;

    await launchUrl(Uri.parse(cvUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        talent['displayName']?.toString().trim().isNotEmpty == true
        ? talent['displayName'].toString()
        : 'Candidat';

    final title = talent['title']?.toString() ?? '';
    final city = talent['city']?.toString() ?? '';
    final bio = talent['bio']?.toString() ?? '';
    final cvFileName = talent['cvFileName']?.toString() ?? '';
    final hasCv = (talent['cvUrl']?.toString() ?? '').trim().isNotEmpty;

    final skills = talent['skills'] is List
        ? (talent['skills'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Profil talent')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TalentProfileHeader(
                displayName: displayName,
                title: title,
                city: city,
              ),
              const SizedBox(height: 16),
              _TalentDetailCard(
                title: 'Présentation',
                icon: Icons.article_outlined,
                child: Text(
                  bio.trim().isEmpty ? 'Aucune présentation renseignée.' : bio,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _TalentDetailCard(
                title: 'Compétences',
                icon: Icons.psychology_outlined,
                child: skills.isEmpty
                    ? Text(
                        'Aucune compétence renseignée.',
                        style: TextStyle(color: Colors.white.withOpacity(0.65)),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.40),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _TalentDetailCard(
                title: 'CV PDF',
                icon: Icons.picture_as_pdf_outlined,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: hasCv ? _openCv : null,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                      hasCv
                          ? (cvFileName.trim().isNotEmpty
                                ? cvFileName
                                : 'Voir le CV PDF')
                          : 'CV PDF non disponible',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TalentProfileHeader extends StatelessWidget {
  final String displayName;
  final String title;
  final String city;

  const _TalentProfileHeader({
    required this.displayName,
    required this.title,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'C';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.greenAccent,
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Color(0xFF06140F),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                if (title.trim().isNotEmpty)
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.72)),
                  ),
                if (city.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    city,
                    style: TextStyle(color: Colors.white.withOpacity(0.52)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TalentDetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _TalentDetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TalentsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onBack;

  const _TalentsEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 8,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white38, size: 58),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
