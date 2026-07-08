import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/features/company/presentation/candidate_video_cv_player_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyTalentsFeedPage extends StatelessWidget {
  const CompanyTalentsFeedPage({super.key});

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

  void _openTalentVideo(BuildContext context, Map<String, dynamic> talent) {
    final videoCvUrl = talent['videoCvUrl']?.toString() ?? '';

    if (videoCvUrl.trim().isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CandidateVideoCvPlayerPage(
          candidateName: talent['displayName']?.toString() ?? 'Candidat',
          jobTitle: talent['title']?.toString() ?? '',
          videoCvUrl: videoCvUrl,
          videoCvThumbnailUrl: talent['videoCvThumbnailUrl']?.toString() ?? '',
          candidateBio: talent['bio']?.toString() ?? '',
          candidateSkills: talent['skills'] is List
              ? (talent['skills'] as List).join(', ')
              : talent['skills']?.toString() ?? '',
        ),
      ),
    );
  }

  void _openTalentProfile(BuildContext context, Map<String, dynamic> talent) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TalentProfileDetailsPage(talent: talent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _talentsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _TalentsInfoState(
            icon: Icons.error_outline,
            title: 'Chargement impossible',
            message: 'Impossible de charger le feed talents pour le moment.',
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final talents = snapshot.data!;

        if (talents.isEmpty) {
          return const _TalentsInfoState(
            icon: Icons.video_library_outlined,
            title: 'Aucun talent visible',
            message:
                'Les candidats Open to Work qui activent la visibilité de leur CV vidéo apparaîtront ici.',
          );
        }

        return Column(
          children: talents.map((talent) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TalentVideoCard(
                talent: talent,
                onOpenVideo: () => _openTalentVideo(context, talent),
                onOpenProfile: () => _openTalentProfile(context, talent),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TalentVideoCard extends StatelessWidget {
  final Map<String, dynamic> talent;
  final VoidCallback onOpenVideo;
  final VoidCallback onOpenProfile;

  const _TalentVideoCard({
    required this.talent,
    required this.onOpenVideo,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        talent['displayName']?.toString().trim().isNotEmpty == true
        ? talent['displayName'].toString()
        : 'Candidat';

    final title = talent['title']?.toString() ?? '';
    final city = talent['city']?.toString() ?? '';
    final bio = talent['bio']?.toString() ?? '';
    final thumbnailUrl = talent['videoCvThumbnailUrl']?.toString() ?? '';

    final skills = talent['skills'] is List
        ? (talent['skills'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return SizedBox(
      height: 620,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl.trim().isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(color: const Color(0xFF161D2E));
                },
              )
            else
              Container(color: const Color(0xFF161D2E)),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.88),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.45),
                  ),
                ),
                child: const Text(
                  'OPEN TO WORK',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onOpenVideo,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.42),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  if (city.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withOpacity(0.72),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: onOpenVideo,
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Vidéo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: onOpenProfile,
                            icon: const Icon(Icons.person_search_outlined),
                            label: const Text('Profil'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TalentProfileDetailsPage extends StatelessWidget {
  final Map<String, dynamic> talent;

  const TalentProfileDetailsPage({super.key, required this.talent});

  Future<void> _openCv(BuildContext context) async {
    final cvUrl = talent['cvUrl']?.toString() ?? '';

    if (cvUrl.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV PDF non disponible.')));
      return;
    }

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
                    onPressed: hasCv ? () => _openCv(context) : null,
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

class _TalentsInfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _TalentsInfoState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white38, size: 54),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
    );
  }
}
