import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/features/company/presentation/schedule_interview_page.dart';
import 'package:jobswipe/features/company/presentation/candidate_video_cv_player_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidateDetailsPage extends StatelessWidget {
  final Map<String, dynamic> candidateData;

  const CandidateDetailsPage({super.key, required this.candidateData});

  Future<void> _showCandidateDetailsSheet({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CandidateDetailsInfoBottomSheet(
          icon: icon,
          iconColor: iconColor,
          title: title,
          message: message,
        );
      },
    );
  }

  Future<void> _openCv(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      await _showCandidateDetailsSheet(
        context: context,
        icon: Icons.picture_as_pdf_outlined,
        iconColor: Colors.amber,
        title: 'CV non disponible',
        message: 'Aucun CV n’est associé à cette candidature.',
      );
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      await _showCandidateDetailsSheet(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        title: 'Ouverture impossible',
        message: 'Impossible d’ouvrir le CV du candidat.',
      );
    }
  }

  void _openVideoCv(BuildContext context) {
    final videoCvUrl = candidateData['candidateVideoCvUrl']?.toString() ?? '';
    final videoCvThumbnailUrl =
        candidateData['candidateVideoCvThumbnailUrl']?.toString() ?? '';

    if (videoCvUrl.trim().isEmpty) {
      _showCandidateDetailsSheet(
        context: context,
        icon: Icons.videocam_outlined,
        iconColor: Colors.amber,
        title: 'CV vidéo non disponible',
        message: 'Aucun CV vidéo n’est associé à cette candidature.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CandidateVideoCvPlayerPage(
          candidateName: candidateData['fullName']?.toString() ?? 'Candidat',
          jobTitle: candidateData['jobTitle']?.toString() ?? '',
          videoCvUrl: videoCvUrl,
          videoCvThumbnailUrl: videoCvThumbnailUrl,
          candidateBio: candidateData['bio']?.toString() ?? '',
          candidateSkills: candidateData['skills']?.toString() ?? '',
        ),
      ),
    );
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
      await _showCandidateDetailsSheet(
        context: context,
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.amber,
        title: 'Candidature introuvable',
        message: 'Impossible de retrouver la candidature à mettre à jour.',
      );
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

    try {
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

      if (!context.mounted) return;

      await _showCandidateDetailsSheet(
        context: context,
        icon: Icons.check_circle_outline,
        iconColor: Colors.greenAccent,
        title: 'Statut mis à jour',
        message: 'Le statut de la candidature a été mis à jour avec succès.',
      );
    } catch (e) {
      if (!context.mounted) return;

      await _showCandidateDetailsSheet(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        title: 'Mise à jour impossible',
        message: 'Une erreur est survenue lors de la mise à jour : $e',
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
    final videoCvUrl = candidateData['candidateVideoCvUrl']?.toString() ?? '';
    final videoCvFileName =
        candidateData['candidateVideoCvFileName']?.toString() ?? '';
    final videoCvThumbnailUrl =
        candidateData['candidateVideoCvThumbnailUrl']?.toString() ?? '';

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
                title: 'CV vidéo candidat',
                icon: Icons.video_library_outlined,
                child: _VideoCvPreviewCard(
                  videoCvUrl: videoCvUrl,
                  videoCvFileName: videoCvFileName,
                  videoCvThumbnailUrl: videoCvThumbnailUrl,
                  onOpen: () => _openVideoCv(context),
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

class _VideoCvPreviewCard extends StatelessWidget {
  final String videoCvUrl;
  final String videoCvFileName;
  final String videoCvThumbnailUrl;
  final VoidCallback onOpen;

  const _VideoCvPreviewCard({
    required this.videoCvUrl,
    required this.videoCvFileName,
    required this.videoCvThumbnailUrl,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideoCv = videoCvUrl.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVideoCv && videoCvThumbnailUrl.trim().isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    videoCvThumbnailUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFF0F1626),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white70,
                            size: 46,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          hasVideoCv
              ? 'CV vidéo chargé : ${videoCvFileName.trim().isNotEmpty ? videoCvFileName : 'video-cv.mp4'}'
              : 'Ce candidat n’a pas ajouté de CV vidéo.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            height: 1.35,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: hasVideoCv ? onOpen : null,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Voir le CV vidéo'),
          ),
        ),
      ],
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

class _CandidateDetailsInfoBottomSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _CandidateDetailsInfoBottomSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 10, 22, bottomPadding + 22),
      decoration: const BoxDecoration(
        color: Color(0xFF101827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Icon(icon, color: iconColor, size: 44),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              height: 1.4,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}
