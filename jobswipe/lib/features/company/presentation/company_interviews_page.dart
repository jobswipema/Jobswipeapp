import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanyInterviewsPage extends ConsumerWidget {
  const CompanyInterviewsPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _interviewsStream(
    String companyId,
  ) {
    return FirebaseFirestore.instance
        .collection('interviews')
        .where('companyId', isEqualTo: companyId)
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

  Future<void> _updateInterviewStatus(
    BuildContext context,
    String interviewId,
    String status,
  ) async {
    await FirebaseFirestore.instance
        .collection('interviews')
        .doc(interviewId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entretien mis à jour.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entretiens')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _interviewsStream(user.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Erreur lors du chargement des entretiens.'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            final interviews = [...docs];

            interviews.sort((a, b) {
              final aDate = a.data()['scheduledAt'];
              final bDate = b.data()['scheduledAt'];

              if (aDate is! Timestamp && bDate is! Timestamp) return 0;
              if (aDate is! Timestamp) return 1;
              if (bDate is! Timestamp) return -1;

              return aDate.toDate().compareTo(bDate.toDate());
            });

            if (interviews.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun entretien planifié pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text(
                  'Calendrier des entretiens',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${interviews.length} entretien(s) planifié(s)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                ...interviews.map((doc) {
                  final data = doc.data();

                  return _InterviewCard(
                    candidateName:
                        data['candidateName']?.toString() ?? 'Candidat',
                    jobTitle: data['jobTitle']?.toString() ?? 'Poste',
                    mode: data['mode']?.toString() ?? '',
                    locationOrLink: data['locationOrLink']?.toString() ?? '',
                    note: data['note']?.toString() ?? '',
                    status: data['status']?.toString() ?? 'planned',
                    date: _formatDate(data['scheduledAt']),
                    time: _formatTime(data['scheduledAt']),
                    onDone: () =>
                        _updateInterviewStatus(context, doc.id, 'done'),
                    onCancel: () =>
                        _updateInterviewStatus(context, doc.id, 'cancelled'),
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

class _InterviewCard extends StatelessWidget {
  final String candidateName;
  final String jobTitle;
  final String mode;
  final String locationOrLink;
  final String note;
  final String status;
  final String date;
  final String time;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  const _InterviewCard({
    required this.candidateName,
    required this.jobTitle,
    required this.mode,
    required this.locationOrLink,
    required this.note,
    required this.status,
    required this.date,
    required this.time,
    required this.onDone,
    required this.onCancel,
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
                radius: 24,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidateName,
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
              _InfoPill(icon: Icons.calendar_month, label: date),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.schedule, label: time),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(icon: Icons.meeting_room_outlined, label: mode),
          if (locationOrLink.trim().isNotEmpty)
            _InfoLine(icon: Icons.link_outlined, label: locationOrLink),
          if (note.trim().isNotEmpty)
            _InfoLine(icon: Icons.notes_outlined, label: note),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status == 'done' ? null : onDone,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Terminé'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status == 'cancelled' ? null : onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoLine({required this.icon, required this.label});

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
