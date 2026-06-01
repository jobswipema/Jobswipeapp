import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

class CandidateApplicationsPage extends ConsumerWidget {
  const CandidateApplicationsPage({super.key});

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

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';

    final date = value.toDate();

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
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes candidatures')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('applications')
              .where('candidateId', isEqualTo: user.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Erreur lors du chargement des candidatures.'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = [...snapshot.data!.docs];

            docs.sort((a, b) {
              final aDate = a.data()['createdAt'];
              final bDate = b.data()['createdAt'];

              if (aDate is! Timestamp && bDate is! Timestamp) return 0;
              if (aDate is! Timestamp) return 1;
              if (bDate is! Timestamp) return -1;

              return bDate.toDate().compareTo(aDate.toDate());
            });

            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Vous n’avez envoyé aucune candidature.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text(
                  'Suivi des candidatures',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${docs.length} candidature(s)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                ...docs.map((doc) {
                  final data = doc.data();

                  final status = data['status']?.toString() ?? 'submitted';
                  final jobTitle =
                      data['jobTitle']?.toString() ?? 'Offre sans titre';
                  final companyName =
                      data['companyName']?.toString() ?? 'Entreprise';

                  final submittedAt = data['submittedAt'] ?? data['createdAt'];
                  final reviewingAt = data['reviewingAt'];
                  final interviewAt = data['interviewAt'];
                  final acceptedAt = data['acceptedAt'];
                  final rejectedAt = data['rejectedAt'];

                  return _ApplicationTimelineCard(
                    jobTitle: jobTitle,
                    companyName: companyName,
                    statusLabel: _statusLabel(status),
                    statusColor: _statusColor(status),
                    steps: [
                      _TimelineStepData(
                        title: 'Candidature envoyée',
                        subtitle: 'Votre candidature a été transmise.',
                        date: _formatDate(submittedAt),
                        isDone: true,
                        isRejected: false,
                      ),
                      _TimelineStepData(
                        title: 'Analyse RH',
                        subtitle: 'Votre profil est en cours d’analyse.',
                        date: _formatDate(reviewingAt),
                        isDone: _isStepDone(status, 'reviewing'),
                        isRejected: false,
                      ),
                      _TimelineStepData(
                        title: 'Entretien',
                        subtitle: 'Un entretien est planifié ou en attente.',
                        date: _formatDate(interviewAt),
                        isDone: _isStepDone(status, 'interview'),
                        isRejected: false,
                      ),
                      if (status == 'rejected')
                        _TimelineStepData(
                          title: 'Candidature refusée',
                          subtitle:
                              'L’entreprise n’a pas retenu votre candidature.',
                          date: _formatDate(rejectedAt),
                          isDone: true,
                          isRejected: true,
                        )
                      else
                        _TimelineStepData(
                          title: 'Décision finale',
                          subtitle: status == 'accepted'
                              ? 'Votre candidature a été acceptée.'
                              : 'En attente de décision finale.',
                          date: _formatDate(acceptedAt),
                          isDone: status == 'accepted',
                          isRejected: false,
                        ),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            jobTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            companyName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
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
