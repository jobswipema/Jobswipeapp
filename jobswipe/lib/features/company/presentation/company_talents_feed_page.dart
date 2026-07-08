import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/features/company/presentation/candidate_video_cv_player_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final feedHeight = MediaQuery.of(context).size.height * 0.62;

    return SizedBox(
      height: feedHeight,
      child: StreamBuilder<List<Map<String, dynamic>>>(
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
            return const Center(child: CircularProgressIndicator());
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

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: talents.length,
            itemBuilder: (context, index) {
              final talent = talents[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TalentVideoCard(
                  talent: talent,
                  onOpenVideo: () => _openTalentVideo(context, talent),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TalentVideoCard extends StatelessWidget {
  final Map<String, dynamic> talent;
  final VoidCallback onOpenVideo;

  const _TalentVideoCard({required this.talent, required this.onOpenVideo});

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

    return ClipRRect(
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
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.45)),
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
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onOpenVideo,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Voir le CV vidéo'),
                  ),
                ),
              ],
            ),
          ),
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
