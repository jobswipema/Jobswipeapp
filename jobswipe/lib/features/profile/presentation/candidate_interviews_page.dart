import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidateInterviewsPage extends ConsumerWidget {
  const CandidateInterviewsPage({super.key});

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

  Future<void> _openLocationOrLink(String value) async {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) return;

    final uri = Uri.tryParse(cleanValue);

    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes entretiens')),
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
                  'Mes entretiens',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${interviews.length} entretien(s)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                ...interviews.map((doc) {
                  final data = doc.data();

                  return _CandidateInterviewCard(
                    companyName:
                        data['companyName']?.toString() ?? 'Entreprise',
                    jobTitle: data['jobTitle']?.toString() ?? 'Poste',
                    mode: data['mode']?.toString() ?? '',
                    locationOrLink: data['locationOrLink']?.toString() ?? '',
                    note: data['note']?.toString() ?? '',
                    status: data['status']?.toString() ?? 'planned',
                    date: _formatDate(data['scheduledAt']),
                    time: _formatTime(data['scheduledAt']),
                    onOpenLink: () => _openLocationOrLink(
                      data['locationOrLink']?.toString() ?? '',
                    ),
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

class _CandidateInterviewCard extends StatelessWidget {
  final String companyName;
  final String jobTitle;
  final String mode;
  final String locationOrLink;
  final String note;
  final String status;
  final String date;
  final String time;
  final VoidCallback onOpenLink;

  const _CandidateInterviewCard({
    required this.companyName,
    required this.jobTitle,
    required this.mode,
    required this.locationOrLink,
    required this.note,
    required this.status,
    required this.date,
    required this.time,
    required this.onOpenLink,
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

  IconData _modeIcon() {
    switch (mode) {
      case 'Présentiel':
        return Icons.location_on_outlined;
      case 'Visio':
        return Icons.video_call_outlined;
      case 'Téléphone':
      default:
        return Icons.phone_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasClickableLink =
        locationOrLink.startsWith('http://') ||
        locationOrLink.startsWith('https://');

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
              _InfoPill(icon: Icons.calendar_month, label: date),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.schedule, label: time),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(icon: _modeIcon(), label: mode),
          if (locationOrLink.trim().isNotEmpty)
            _InfoLine(
              icon: hasClickableLink
                  ? Icons.link_outlined
                  : Icons.place_outlined,
              label: locationOrLink,
            ),
          if (note.trim().isNotEmpty)
            _InfoLine(icon: Icons.notes_outlined, label: note),
          if (hasClickableLink) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onOpenLink,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ouvrir le lien'),
              ),
            ),
          ],
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
