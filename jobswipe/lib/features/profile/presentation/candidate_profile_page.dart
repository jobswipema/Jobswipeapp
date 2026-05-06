import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:jobswipe/features/profile/presentation/edit_candidate_profile_page.dart';

class CandidateProfilePage extends ConsumerWidget {
  const CandidateProfilePage({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<List<ApplicationModel>> _applicationsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('candidateId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final applications = snapshot.docs
              .map(ApplicationModel.fromFirestore)
              .toList();

          applications.sort((a, b) {
            final aDate = a.createdAt;
            final bDate = b.createdAt;

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;

            return bDate.compareTo(aDate);
          });

          return applications;
        });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'reviewing':
        return 'En analyse';
      case 'interview':
        return 'Entretien';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'submitted':
      default:
        return 'Reçue';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reviewing':
        return Colors.blueAccent;
      case 'interview':
        return Colors.amber;
      case 'accepted':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'submitted':
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil candidat'),
        actions: [
          IconButton(
            onPressed: ref.read(authProvider.notifier).logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profileStream(user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return const Center(
                child: Text('Erreur lors du chargement du profil.'),
              );
            }

            if (!profileSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = profileSnapshot.data!.data() ?? {};

            final displayName =
                data['displayName']?.toString() ?? user.displayName;
            final email = data['email']?.toString() ?? user.email;
            final title =
                data['title']?.toString() ??
                'Titre professionnel non renseigné';
            final city = data['city']?.toString() ?? 'Ville non renseignée';
            final phone =
                data['phone']?.toString() ?? 'Téléphone non renseigné';
            final bio =
                data['bio']?.toString() ??
                'Ajoutez une courte présentation professionnelle pour améliorer votre profil.';
            final skillsRaw = data['skills'];
            final skills = skillsRaw is List
                ? skillsRaw.map((e) => e.toString()).toList()
                : <String>[];

            return StreamBuilder<List<ApplicationModel>>(
              stream: _applicationsStream(user.id),
              builder: (context, applicationsSnapshot) {
                final applications = applicationsSnapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHeader(
                        displayName: displayName,
                        title: title,
                        email: email,
                        city: city,
                        phone: phone,
                      ),
                      const SizedBox(height: 18),
                      _BioCard(bio: bio),
                      const SizedBox(height: 18),
                      _SkillsCard(skills: skills),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EditCandidateProfilePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Modifier mon profil'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Mes candidatures',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (applicationsSnapshot.hasError)
                        const _InfoCard(
                          text:
                              'Erreur lors du chargement de vos candidatures.',
                        )
                      else if (!applicationsSnapshot.hasData)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (applications.isEmpty)
                        const _InfoCard(
                          text: 'Vous n’avez envoyé aucune candidature.',
                        )
                      else
                        ...applications.map((application) {
                          return _ApplicationCard(
                            title: application.jobTitle,
                            companyName: application.companyName,
                            status: _statusLabel(application.status),
                            statusColor: _statusColor(application.status),
                          );
                        }).toList(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String title;
  final String email;
  final String city;
  final String phone;

  const _ProfileHeader({
    required this.displayName,
    required this.title,
    required this.email,
    required this.city,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileLine(icon: Icons.email_outlined, text: email),
          const SizedBox(height: 8),
          _ProfileLine(icon: Icons.location_on_outlined, text: city),
          const SizedBox(height: 8),
          _ProfileLine(icon: Icons.phone_outlined, text: phone),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _BioCard extends StatelessWidget {
  final String bio;

  const _BioCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Présentation',
      child: Text(
        bio,
        style: TextStyle(
          color: Colors.white.withOpacity(0.75),
          height: 1.45,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  final List<String> skills;

  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Compétences',
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A52),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.45),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String title;
  final String companyName;
  final String status;
  final Color statusColor;

  const _ApplicationCard({
    required this.title,
    required this.companyName,
    required this.status,
    required this.statusColor,
  });

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
            title.isEmpty ? 'Offre sans titre' : title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            companyName.isEmpty ? 'Entreprise' : companyName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withOpacity(0.50)),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
