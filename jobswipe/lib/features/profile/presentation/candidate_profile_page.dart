import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/features/profile/presentation/candidate_interviews_page.dart';
import 'package:jobswipe/features/profile/presentation/edit_candidate_profile_page.dart';
import 'package:jobswipe/features/profile/presentation/widgets/candidate_favorites_section.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:jobswipe/shared/services/cloudinary_service.dart';

class CandidateProfilePage extends ConsumerStatefulWidget {
  const CandidateProfilePage({super.key});

  @override
  ConsumerState<CandidateProfilePage> createState() =>
      _CandidateProfilePageState();
}

class _CandidateProfilePageState extends ConsumerState<CandidateProfilePage> {
  bool _isUploadingCv = false;
  int _selectedTab = 0;

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

  Future<void> _uploadCv() async {
    final user = ref.read(authProvider);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lire le fichier PDF.')),
      );
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le CV ne doit pas dépasser 5 Mo.')),
      );
      return;
    }

    setState(() => _isUploadingCv = true);

    try {
      final cvUrl = await CloudinaryService.uploadPdf(
        fileBytes: file.bytes!,
        fileName: file.name,
        folder: 'jobswipe/cvs/${user.id}',
      );

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'cvUrl': cvUrl,
        'cvFileName': file.name,
        'cvUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'hasCv': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV téléversé avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur upload CV : $e')));
    } finally {
      if (mounted) setState(() => _isUploadingCv = false);
    }
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
  Widget build(BuildContext context) {
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

            final cvUrl = data['cvUrl']?.toString() ?? '';
            final cvFileName = data['cvFileName']?.toString() ?? '';

            final skillsRaw = data['skills'];
            final skills = skillsRaw is List
                ? skillsRaw.map((e) => e.toString()).toList()
                : <String>[];

            return StreamBuilder<List<ApplicationModel>>(
              stream: _applicationsStream(user.id),
              builder: (context, applicationsSnapshot) {
                final applications = applicationsSnapshot.data ?? [];
                final interviewsCount = applications
                    .where((a) => a.status == 'interview')
                    .length;
                final acceptedCount = applications
                    .where((a) => a.status == 'accepted')
                    .length;

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
                      _QuickStats(
                        applicationsCount: applications.length,
                        interviewsCount: interviewsCount,
                        acceptedCount: acceptedCount,
                      ),
                      const SizedBox(height: 18),
                      _ProfileTabs(
                        selectedIndex: _selectedTab,
                        onChanged: (index) {
                          setState(() => _selectedTab = index);
                        },
                      ),
                      const SizedBox(height: 18),
                      if (_selectedTab == 0)
                        _ProfileTabContent(
                          bio: bio,
                          skills: skills,
                          cvUrl: cvUrl,
                          cvFileName: cvFileName,
                          isUploadingCv: _isUploadingCv,
                          onUploadCv: _uploadCv,
                          onEditProfile: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EditCandidateProfilePage(),
                              ),
                            );
                          },
                        )
                      else if (_selectedTab == 1)
                        const _InterviewsTabContent()
                      else if (_selectedTab == 2)
                        _ApplicationsTabContent(
                          applications: applications,
                          statusLabel: _statusLabel,
                          statusColor: _statusColor,
                        )
                      else
                        const _FavoritesTabContent(),
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

class _ProfileTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ProfileTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.person_outline, 'Profil'),
      (Icons.event_available_outlined, 'Entretiens'),
      (Icons.assignment_outlined, 'Candidatures'),
      (Icons.bookmark_outline, 'Favoris'),
    ];

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blueAccent.withOpacity(0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.$1,
                      size: 22,
                      color: isSelected ? Colors.blueAccent : Colors.white54,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? Colors.blueAccent : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProfileTabContent extends StatelessWidget {
  final String bio;
  final List<String> skills;
  final String cvUrl;
  final String cvFileName;
  final bool isUploadingCv;
  final VoidCallback onUploadCv;
  final VoidCallback onEditProfile;

  const _ProfileTabContent({
    required this.bio,
    required this.skills,
    required this.cvUrl,
    required this.cvFileName,
    required this.isUploadingCv,
    required this.onUploadCv,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuActionButton(
          title: 'Modifier mon profil',
          subtitle: 'Informations, ville, téléphone, compétences',
          icon: Icons.edit_outlined,
          color: Colors.blueAccent,
          onTap: onEditProfile,
        ),
        const SizedBox(height: 14),
        _CvCard(
          cvUrl: cvUrl,
          cvFileName: cvFileName,
          isUploading: isUploadingCv,
          onUpload: onUploadCv,
        ),
        const SizedBox(height: 14),
        _BioCard(bio: bio),
        const SizedBox(height: 14),
        _SkillsCard(skills: skills),
      ],
    );
  }
}

class _InterviewsTabContent extends StatelessWidget {
  const _InterviewsTabContent();

  @override
  Widget build(BuildContext context) {
    return const CandidateInterviewsPageBody();
  }
}

class CandidateInterviewsPageBody extends ConsumerWidget {
  const CandidateInterviewsPageBody({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _interviewsStream(
    String candidateId,
  ) {
    return FirebaseFirestore.instance
        .collection('interviews')
        .where('candidateId', isEqualTo: candidateId)
        .snapshots();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date non définie';

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '--:--';

    final date = timestamp.toDate();

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _interviewsStream(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _InfoCard(
            text: 'Erreur lors du chargement des entretiens.',
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final interviews = [...snapshot.data!.docs];

        interviews.sort((a, b) {
          final aDate = a.data()['scheduledAt'];
          final bDate = b.data()['scheduledAt'];

          if (aDate is! Timestamp && bDate is! Timestamp) return 0;
          if (aDate is! Timestamp) return 1;
          if (bDate is! Timestamp) return -1;

          return aDate.toDate().compareTo(bDate.toDate());
        });

        if (interviews.isEmpty) {
          return const _InfoCard(
            text: 'Aucun entretien planifié pour le moment.',
          );
        }

        return Column(
          children: interviews.map((doc) {
            final data = doc.data();

            return _InterviewMiniCard(
              companyName: data['companyName']?.toString() ?? 'Entreprise',
              jobTitle: data['jobTitle']?.toString() ?? 'Poste',
              mode: data['mode']?.toString() ?? '',
              locationOrLink: data['locationOrLink']?.toString() ?? '',
              note: data['note']?.toString() ?? '',
              status: data['status']?.toString() ?? 'planned',
              date: _formatDate(data['scheduledAt']),
              time: _formatTime(data['scheduledAt']),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ApplicationsTabContent extends StatelessWidget {
  final List<ApplicationModel> applications;
  final String Function(String status) statusLabel;
  final Color Function(String status) statusColor;

  const _ApplicationsTabContent({
    required this.applications,
    required this.statusLabel,
    required this.statusColor,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isStepDone(String currentStatus, String step) {
    const order = {
      'submitted': 1,
      'reviewing': 2,
      'interview': 3,
      'accepted': 4,
      'rejected': 4,
    };

    return (order[currentStatus] ?? 1) >= (order[step] ?? 1);
  }

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const _InfoCard(text: 'Vous n’avez envoyé aucune candidature.');
    }

    return Column(
      children: applications.map((application) {
        final color = statusColor(application.status);

        return _ApplicationTimelineCard(
          jobTitle: application.jobTitle.isEmpty
              ? 'Offre sans titre'
              : application.jobTitle,
          companyName: application.companyName.isEmpty
              ? 'Entreprise'
              : application.companyName,
          statusLabel: statusLabel(application.status),
          statusColor: color,
          steps: [
            _TimelineStepData(
              title: 'Candidature envoyée',
              subtitle: 'Votre candidature a été transmise.',
              date: _formatDate(
                application.submittedAt ?? application.createdAt,
              ),
              isDone: true,
              isRejected: false,
            ),
            _TimelineStepData(
              title: 'Analyse RH',
              subtitle: 'Votre profil est en cours d’analyse.',
              date: _formatDate(application.reviewingAt),
              isDone: _isStepDone(application.status, 'reviewing'),
              isRejected: false,
            ),
            _TimelineStepData(
              title: 'Entretien',
              subtitle: 'Un entretien est planifié ou en attente.',
              date: _formatDate(application.interviewAt),
              isDone: _isStepDone(application.status, 'interview'),
              isRejected: false,
            ),
            if (application.status == 'rejected')
              _TimelineStepData(
                title: 'Candidature refusée',
                subtitle: 'L’entreprise n’a pas retenu votre candidature.',
                date: _formatDate(application.rejectedAt),
                isDone: true,
                isRejected: true,
              )
            else
              _TimelineStepData(
                title: 'Décision finale',
                subtitle: application.status == 'accepted'
                    ? 'Votre candidature a été acceptée.'
                    : 'En attente de décision finale.',
                date: _formatDate(application.acceptedAt),
                isDone: application.status == 'accepted',
                isRejected: false,
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _ApplicationTimelineCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String statusLabel;
  final Color statusColor;
  final List<_TimelineStepData> steps;

  const _ApplicationTimelineCard({
    required this.jobTitle,
    required this.companyName,
    required this.statusLabel,
    required this.statusColor,
    required this.steps,
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
            jobTitle,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            companyName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withOpacity(0.50)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            return _TimelineStep(
              data: steps[index],
              isLast: index == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStepData {
  final String title;
  final String subtitle;
  final String date;
  final bool isDone;
  final bool isRejected;

  const _TimelineStepData({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.isDone,
    required this.isRejected,
  });
}

class _TimelineStep extends StatelessWidget {
  final _TimelineStepData data;
  final bool isLast;

  const _TimelineStep({required this.data, required this.isLast});

  Color get _color {
    if (data.isRejected) return Colors.redAccent;
    if (data.isDone) return Colors.greenAccent;
    return Colors.white30;
  }

  IconData get _icon {
    if (data.isRejected) return Icons.close;
    if (data.isDone) return Icons.check;
    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(color: _color.withOpacity(0.65)),
              ),
              child: Icon(_icon, size: 16, color: _color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: _color.withOpacity(data.isDone ? 0.45 : 0.18),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: data.isDone ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(data.isDone ? 0.70 : 0.42),
                    height: 1.3,
                  ),
                ),
                if (data.date.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    data.date,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesTabContent extends StatelessWidget {
  const _FavoritesTabContent();

  @override
  Widget build(BuildContext context) {
    return const CandidateFavoritesSection();
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
    final firstLetter = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'C';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blueAccent,
            child: Text(
              firstLetter,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.70),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$city • $phone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.48),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.48),
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

class _QuickStats extends StatelessWidget {
  final int applicationsCount;
  final int interviewsCount;
  final int acceptedCount;

  const _QuickStats({
    required this.applicationsCount,
    required this.interviewsCount,
    required this.acceptedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            title: 'Candidatures',
            value: applicationsCount.toString(),
            icon: Icons.assignment_outlined,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            title: 'Entretiens',
            value: interviewsCount.toString(),
            icon: Icons.event_available_outlined,
            color: Colors.amberAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            title: 'Acceptées',
            value: acceptedCount.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFF161D2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
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

class _CvCard extends StatelessWidget {
  final String cvUrl;
  final String cvFileName;
  final bool isUploading;
  final VoidCallback onUpload;

  const _CvCard({
    required this.cvUrl,
    required this.cvFileName,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final hasCv = cvUrl.trim().isNotEmpty;

    return _SectionCard(
      title: 'CV PDF',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasCv
                ? 'CV chargé : ${cvFileName.isEmpty ? 'cv.pdf' : cvFileName}'
                : 'Aucun CV téléversé.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : onUpload,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                isUploading
                    ? 'Téléversement...'
                    : hasCv
                    ? 'Remplacer mon CV'
                    : 'Téléverser mon CV',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewMiniCard extends StatelessWidget {
  final String companyName;
  final String jobTitle;
  final String mode;
  final String locationOrLink;
  final String note;
  final String status;
  final String date;
  final String time;

  const _InterviewMiniCard({
    required this.companyName,
    required this.jobTitle,
    required this.mode,
    required this.locationOrLink,
    required this.note,
    required this.status,
    required this.date,
    required this.time,
  });

  Color _statusColor() {
    switch (status) {
      case 'done':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      case 'planned':
      default:
        return Colors.blueAccent;
    }
  }

  String _statusLabel() {
    switch (status) {
      case 'done':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      case 'planned':
      default:
        return 'Planifié';
    }
  }

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
          Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.business, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.60)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _statusColor().withOpacity(0.50)),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: _statusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniInfoPill(icon: Icons.calendar_month, label: date),
              const SizedBox(width: 8),
              _MiniInfoPill(icon: Icons.schedule, label: time),
            ],
          ),
          const SizedBox(height: 10),
          _MiniInfoLine(icon: Icons.meeting_room_outlined, label: mode),
          if (locationOrLink.trim().isNotEmpty)
            _MiniInfoLine(icon: Icons.place_outlined, label: locationOrLink),
          if (note.trim().isNotEmpty)
            _MiniInfoLine(icon: Icons.notes_outlined, label: note),
        ],
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1626),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white70),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfoLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                height: 1.35,
              ),
            ),
          ),
        ],
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
        border: Border.all(color: Colors.white10),
      ),
      child: Text(text),
    );
  }
}
