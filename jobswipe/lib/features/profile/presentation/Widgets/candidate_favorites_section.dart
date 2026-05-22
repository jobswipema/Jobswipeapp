import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

class CandidateFavoritesSection extends ConsumerWidget {
  const CandidateFavoritesSection({super.key});

  Future<List<JobOffer>> _loadFavoriteJobs(List<String> jobIds) async {
    if (jobIds.isEmpty) return [];

    final futures = jobIds.map((jobId) {
      return FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    });

    final docs = await Future.wait(futures);

    return docs.where((doc) => doc.exists).map(JobOffer.fromFirestore).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_favorites')
          .where('candidateId', isEqualTo: user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _InfoCard(
            text: 'Erreur lors du chargement des favoris.',
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final favoriteDocs = snapshot.data!.docs;

        if (favoriteDocs.isEmpty) {
          return const _InfoCard(text: 'Aucune offre favorite pour le moment.');
        }

        final jobIds = favoriteDocs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return data['jobId']?.toString() ?? '';
            })
            .where((id) => id.isNotEmpty)
            .toList();

        return FutureBuilder<List<JobOffer>>(
          future: _loadFavoriteJobs(jobIds),
          builder: (context, jobsSnapshot) {
            if (jobsSnapshot.hasError) {
              return const _InfoCard(
                text: 'Erreur lors du chargement des offres favorites.',
              );
            }

            if (!jobsSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final jobs = jobsSnapshot.data!;

            if (jobs.isEmpty) {
              return const _InfoCard(text: 'Aucune offre favorite disponible.');
            }

            return Column(
              children: jobs.map((job) {
                return _FavoriteJobCard(job: job);
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _FavoriteJobCard extends StatelessWidget {
  final JobOffer job;

  const _FavoriteJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${job.companyName} • ${job.location}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: job.contractType),
              _Pill(label: job.experience),
              _Pill(label: job.salary),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text),
    );
  }
}
