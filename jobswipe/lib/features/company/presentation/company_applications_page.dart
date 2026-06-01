import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'candidate_details_page.dart';

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

  Future<void> _openCv(BuildContext context, String cvUrl) async {
    if (cvUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun CV disponible pour ce candidat.')),
      );
      return;
    }

    final launched = await launchUrl(
      Uri.parse(cvUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le CV.')),
      );
    }
  }

  Future<void> _createStatusNotification({
    required String candidateId,
    required String jobTitle,
    required String companyName,
    required String status,
  }) async {
    final statusLabel = switch (status) {
      'reviewing' => 'en analyse',
      'interview' => 'passée en entretien',
      'accepted' => 'acceptée',
      'rejected' => 'refusée',
      _ => 'reçue',
    };

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': candidateId,
      'title': 'Mise à jour de candidature',
      'message':
          '$companyName a mis à jour votre candidature pour "$jobTitle" : $statusLabel.',
      'type': 'application_status',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateStatus(
    BuildContext context,
    ApplicationModel application,
    String status,
  ) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'reviewing') {
      updateData['reviewingAt'] = FieldValue.serverTimestamp();
    }

    if (status == 'interview') {
      updateData['interviewAt'] = FieldValue.serverTimestamp();
    }

    if (status == 'accepted') {
      updateData['acceptedAt'] = FieldValue.serverTimestamp();
    }

    if (status == 'rejected') {
      updateData['rejectedAt'] = FieldValue.serverTimestamp();
    }

    await FirebaseFirestore.instance
        .collection('applications')
        .doc(application.id)
        .update(updateData);

    await _createStatusNotification(
      candidateId: application.candidateId,
      jobTitle: application.jobTitle,
      companyName: application.companyName,
      status: status,
    );

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
      default:
        return Colors.white70;
    }
  }

  void _openCandidateProfile(
    BuildContext context,
    ApplicationModel application,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CandidateDetailsPage(
          candidateData: {
            'applicationId': application.id,
            'candidateId': application.candidateId,
            'companyId': application.companyId,
            'jobId': application.jobId,
            'jobTitle': application.jobTitle,
            'companyName': application.companyName,
            'status': application.status,
            'fullName': application.candidateName,
            'email': application.candidateEmail,
            'phone': application.candidatePhone,
            'city': application.candidateCity,
            'bio': application.candidateBio,
            'skills': application.candidateSkills,
            'candidateCvUrl': application.candidateCvUrl,
            'candidateCvFileName': application.candidateCvFileName,
          },
        ),
      ),
    );
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
                    final candidateName =
                        application.candidateName.trim().isNotEmpty
                        ? application.candidateName
                        : application.candidateId;

                    final hasCv = application.candidateCvUrl.trim().isNotEmpty;

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
                            candidateName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (application.candidateEmail.isNotEmpty) ...[
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
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _openCandidateProfile(context, application),
                              icon: const Icon(Icons.person_search_outlined),
                              label: const Text('Voir le profil candidat'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: hasCv
                                  ? () => _openCv(
                                      context,
                                      application.candidateCvUrl,
                                    )
                                  : null,
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: Text(
                                hasCv ? 'Voir le CV' : 'CV non disponible',
                              ),
                            ),
                          ),
                          if (hasCv &&
                              application.candidateCvFileName.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              application.candidateCvFileName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusButton(
                                label: 'Analyse',
                                onPressed: () => _updateStatus(
                                  context,
                                  application,
                                  'reviewing',
                                ),
                              ),
                              _StatusButton(
                                label: 'Entretien',
                                onPressed: () => _updateStatus(
                                  context,
                                  application,
                                  'interview',
                                ),
                              ),
                              _StatusButton(
                                label: 'Accepter',
                                onPressed: () => _updateStatus(
                                  context,
                                  application,
                                  'accepted',
                                ),
                              ),
                              _StatusButton(
                                label: 'Refuser',
                                onPressed: () => _updateStatus(
                                  context,
                                  application,
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
