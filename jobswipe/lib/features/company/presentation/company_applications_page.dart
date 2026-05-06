import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class CompanyApplicationsPage extends StatelessWidget {
  final JobOffer job;

  const CompanyApplicationsPage({super.key, required this.job});

  Stream<List<ApplicationModel>> _applicationsStream() {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: job.id)
        .where('companyId', isEqualTo: job.companyId)
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

  Future<void> _updateStatus(
    BuildContext context,
    String applicationId,
    String status,
  ) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut de candidature mis à jour.')),
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatures')),
      body: SafeArea(
        child: StreamBuilder<List<ApplicationModel>>(
          stream: _applicationsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Erreur lors du chargement des candidatures.'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final applications = snapshot.data!;

            if (applications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucune candidature reçue pour l’offre "${job.title}".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${applications.length} candidature(s) reçue(s)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...applications.map((application) {
                    final candidateDisplayName =
                        application.candidateName.trim().isNotEmpty
                        ? application.candidateName
                        : application.candidateId;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161D2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Candidat',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            candidateDisplayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (application.candidateEmail.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              application.candidateEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                application.status,
                              ).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _statusColor(
                                  application.status,
                                ).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              _statusLabel(application.status),
                              style: TextStyle(
                                color: _statusColor(application.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusButton(
                                label: 'Analyse',
                                onPressed: () => _updateStatus(
                                  context,
                                  application.id,
                                  'reviewing',
                                ),
                              ),
                              _StatusButton(
                                label: 'Entretien',
                                onPressed: () => _updateStatus(
                                  context,
                                  application.id,
                                  'interview',
                                ),
                              ),
                              _StatusButton(
                                label: 'Accepter',
                                onPressed: () => _updateStatus(
                                  context,
                                  application.id,
                                  'accepted',
                                ),
                              ),
                              _StatusButton(
                                label: 'Refuser',
                                onPressed: () => _updateStatus(
                                  context,
                                  application.id,
                                  'rejected',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _StatusButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
