import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/features/company/presentation/schedule_interview_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidateDetailsPage extends StatelessWidget {
  final Map<String, dynamic> candidateData;

  const CandidateDetailsPage({super.key, required this.candidateData});

  Future<void> _openCv(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV non disponible.')));
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
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
    String applicationId,
    String candidateId,
    String jobTitle,
    String companyName,
    String status,
  ) async {
    if (applicationId.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Candidature introuvable.')));
      return;
    }

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
        .doc(applicationId)
        .update(updateData);

    await _createStatusNotification(
      candidateId: candidateId,
      jobTitle: jobTitle,
      companyName: companyName,
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

  @override
  Widget build(BuildContext context) {
    final applicationId = candidateData['applicationId']?.toString() ?? '';
    final candidateId = candidateData['candidateId']?.toString() ?? '';
    final companyId = candidateData['companyId']?.toString() ?? '';
    final jobId = candidateData['jobId']?.toString() ?? '';
    final jobTitle = candidateData['jobTitle']?.toString() ?? '';
    final companyName =
        candidateData['companyName']?.toString() ?? 'Entreprise';
    final status = candidateData['status']?.toString() ?? 'submitted';

    final fullName = candidateData['fullName']?.toString() ?? '';
    final email = candidateData['email']?.toString() ?? '';
    final phone = candidateData['phone']?.toString() ?? '';
    final city = candidateData['city']?.toString() ?? '';
    final bio = candidateData['bio']?.toString() ?? '';
    final skills = candidateData['skills']?.toString() ?? '';
    final cvUrl = candidateData['candidateCvUrl']?.toString() ?? '';
    final cvFileName = candidateData['candidateCvFileName']?.toString() ?? '';

    final displayName = fullName.trim().isEmpty ? 'Candidat' : fullName.trim();
    final firstLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    final fullCandidateData = {
      ...candidateData,
      'applicationId': applicationId,
      'candidateId': candidateId,
      'companyId': companyId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Profil candidat')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            children: [
              _HeaderCard(
                firstLetter: firstLetter,
                displayName: displayName,
                email: email,
                jobTitle: jobTitle,
                status: status,
                statusLabel: _statusLabel(status),
                statusColor: _statusColor(status),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Coordonnées',
                icon: Icons.contact_mail_outlined,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: phone,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Ville',
                      value: city,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Profil professionnel',
                icon: Icons.badge_outlined,
                child: Column(
                  children: [
                    _TextBlock(label: 'Compétences', value: skills),
                    const SizedBox(height: 14),
                    _TextBlock(label: 'Présentation', value: bio),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'CV candidat',
                icon: Icons.picture_as_pdf_outlined,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: cvUrl.trim().isEmpty
                        ? null
                        : () => _openCv(context, cvUrl),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                      cvFileName.trim().isNotEmpty ? cvFileName : 'Voir le CV',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Actions de recrutement',
                icon: Icons.manage_accounts_outlined,
                child: Column(
                  children: [
                    _ActionButton(
                      label: 'Passer en analyse',
                      icon: Icons.manage_search,
                      outlined: true,
                      onPressed: () => _updateStatus(
                        context,
                        applicationId,
                        candidateId,
                        jobTitle,
                        companyName,
                        'reviewing',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      label: 'Planifier un entretien',
                      icon: Icons.event_available,
                      outlined: false,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScheduleInterviewPage(
                              candidateData: fullCandidateData,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      label: 'Accepter la candidature',
                      icon: Icons.check_circle_outline,
                      outlined: true,
                      onPressed: () => _updateStatus(
                        context,
                        applicationId,
                        candidateId,
                        jobTitle,
                        companyName,
                        'accepted',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      label: 'Refuser la candidature',
                      icon: Icons.close,
                      outlined: true,
                      onPressed: () => _updateStatus(
                        context,
                        applicationId,
                        candidateId,
                        jobTitle,
                        companyName,
                        'rejected',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String firstLetter;
  final String displayName;
  final String email;
  final String jobTitle;
  final String status;
  final String statusLabel;
  final Color statusColor;

  const _HeaderCard({
    required this.firstLetter,
    required this.displayName,
    required this.email,
    required this.jobTitle,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
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
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Text(
              firstLetter,
              style: const TextStyle(
                fontSize: 26,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jobTitle.isEmpty ? email : jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(0.55)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'Non renseigné' : value.trim();

    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cleanValue,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String label;
  final String value;

  const _TextBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'Non renseigné' : value.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cleanValue,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool outlined;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.outlined,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
