import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/features/company/presentation/schedule_interview_page.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'candidate_details_page.dart';

class CompanyApplicationsPage extends StatefulWidget {
  final JobOffer job;

  const CompanyApplicationsPage({super.key, required this.job});

  @override
  State<CompanyApplicationsPage> createState() =>
      _CompanyApplicationsPageState();
}

class _CompanyApplicationsPageState extends State<CompanyApplicationsPage> {
  String _selectedFilter = 'all';

  Stream<List<ApplicationModel>> _applicationsStream() {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: widget.job.id)
        .where('companyId', isEqualTo: widget.job.companyId)
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

  List<ApplicationModel> _filteredApplications(
    List<ApplicationModel> applications,
  ) {
    if (_selectedFilter == 'all') return applications;

    return applications.where((a) => a.status == _selectedFilter).toList();
  }

  Future<void> _openCv(BuildContext context, String cvUrl) async {
    if (cvUrl.trim().isEmpty) {
      _showInfoSheet(
        context,
        icon: Icons.picture_as_pdf_outlined,
        iconColor: Colors.amber,
        title: 'CV non disponible',
        message: 'Aucun CV PDF n’est associé à cette candidature.',
      );
      return;
    }

    final launched = await launchUrl(
      Uri.parse(cvUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      _showInfoSheet(
        context,
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        title: 'Ouverture impossible',
        message: 'Impossible d’ouvrir le CV pour le moment.',
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
      _showInfoSheet(
        context,
        icon: Icons.check_circle_outline,
        iconColor: Colors.greenAccent,
        title: 'Statut mis à jour',
        message: 'Le statut de la candidature a été mis à jour avec succès.',
      );
    }
  }

  Future<void> _confirmFinalStatus(
    BuildContext context,
    ApplicationModel application,
    String status,
  ) async {
    final isAccepted = status == 'accepted';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ConfirmActionSheet(
          icon: isAccepted ? Icons.check_circle_outline : Icons.cancel_outlined,
          iconColor: isAccepted ? Colors.greenAccent : Colors.redAccent,
          title: isAccepted
              ? 'Accepter la candidature'
              : 'Refuser la candidature',
          message: isAccepted
              ? 'Confirmez-vous l’acceptation de la candidature de ${application.candidateName} ? Le candidat sera notifié.'
              : 'Confirmez-vous le refus de la candidature de ${application.candidateName} ? Le candidat sera notifié.',
          confirmLabel: isAccepted ? 'Accepter' : 'Refuser',
          confirmColor: isAccepted ? Colors.greenAccent : Colors.redAccent,
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await _updateStatus(context, application, status);
  }

  void _planInterview(BuildContext context, ApplicationModel application) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleInterviewPage(
          candidateData: {
            'applicationId': application.id,
            'candidateId': application.candidateId,
            'companyId': application.companyId,
            'jobId': application.jobId,
            'jobTitle': application.jobTitle,
            'companyName': application.companyName,
            'fullName': application.candidateName,
            'email': application.candidateEmail,
            'phone': application.candidatePhone,
            'city': application.candidateCity,
            'bio': application.candidateBio,
            'skills': application.candidateSkills,
            'candidateCvUrl': application.candidateCvUrl,
            'candidateCvFileName': application.candidateCvFileName,
            'candidateVideoCvUrl': application.candidateVideoCvUrl,
            'candidateVideoCvFileName': application.candidateVideoCvFileName,
            'candidateVideoCvThumbnailUrl':
                application.candidateVideoCvThumbnailUrl,
          },
        ),
      ),
    );
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
            'candidateVideoCvUrl': application.candidateVideoCvUrl,
            'candidateVideoCvFileName': application.candidateVideoCvFileName,
            'candidateVideoCvThumbnailUrl':
                application.candidateVideoCvThumbnailUrl,
          },
        ),
      ),
    );
  }

  Map<String, int> _statusCounts(List<ApplicationModel> applications) {
    final counts = <String, int>{
      'all': applications.length,
      'submitted': 0,
      'reviewing': 0,
      'interview': 0,
      'accepted': 0,
      'rejected': 0,
    };

    for (final application in applications) {
      counts[application.status] = (counts[application.status] ?? 0) + 1;
    }

    return counts;
  }

  void _showInfoSheet(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _InfoSheet(
          icon: icon,
          iconColor: iconColor,
          title: title,
          message: message,
        );
      },
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
            final counts = _statusCounts(applications);
            final filteredApplications = _filteredApplications(applications);

            if (applications.isEmpty) {
              return _EmptyApplications(jobTitle: widget.job.title);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JobHeader(
                    jobTitle: widget.job.title,
                    applicationsCount: applications.length,
                  ),
                  const SizedBox(height: 16),
                  _StatusFilters(
                    selectedFilter: _selectedFilter,
                    counts: counts,
                    onChanged: (value) {
                      setState(() => _selectedFilter = value);
                    },
                    statusLabel: _statusLabel,
                  ),
                  const SizedBox(height: 18),
                  if (filteredApplications.isEmpty)
                    _EmptyFilteredApplications(
                      label: _selectedFilter == 'all'
                          ? 'Aucune candidature.'
                          : 'Aucune candidature avec le statut "${_statusLabel(_selectedFilter)}".',
                    )
                  else
                    ...filteredApplications.map((application) {
                      return _ApplicationCard(
                        application: application,
                        statusLabel: _statusLabel,
                        statusColor: _statusColor,
                        onOpenProfile: () =>
                            _openCandidateProfile(context, application),
                        onOpenCv: () =>
                            _openCv(context, application.candidateCvUrl),
                        onReview: application.status == 'reviewing'
                            ? null
                            : () => _updateStatus(
                                context,
                                application,
                                'reviewing',
                              ),
                        onPlanInterview: () =>
                            _planInterview(context, application),
                        onAccept: application.status == 'accepted'
                            ? null
                            : () => _confirmFinalStatus(
                                context,
                                application,
                                'accepted',
                              ),
                        onReject: application.status == 'rejected'
                            ? null
                            : () => _confirmFinalStatus(
                                context,
                                application,
                                'rejected',
                              ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  final String jobTitle;
  final int applicationsCount;

  const _JobHeader({required this.jobTitle, required this.applicationsCount});

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
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.work_outline,
              color: Colors.blueAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$applicationsCount candidature(s) reçue(s)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

class _StatusFilters extends StatelessWidget {
  final String selectedFilter;
  final Map<String, int> counts;
  final ValueChanged<String> onChanged;
  final String Function(String status) statusLabel;

  const _StatusFilters({
    required this.selectedFilter,
    required this.counts,
    required this.onChanged,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'Tous'),
      ('submitted', statusLabel('submitted')),
      ('reviewing', statusLabel('reviewing')),
      ('interview', statusLabel('interview')),
      ('accepted', statusLabel('accepted')),
      ('rejected', statusLabel('rejected')),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final value = filter.$1;
          final label = filter.$2;
          final selected = selectedFilter == value;
          final count = counts[value] ?? 0;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blueAccent.withOpacity(0.18)
                    : const Color(0xFF161D2E),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.blueAccent.withOpacity(0.85)
                      : Colors.white10,
                ),
              ),
              child: Center(
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.white60,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final String Function(String status) statusLabel;
  final Color Function(String status) statusColor;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCv;
  final VoidCallback? onReview;
  final VoidCallback onPlanInterview;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _ApplicationCard({
    required this.application,
    required this.statusLabel,
    required this.statusColor,
    required this.onOpenProfile,
    required this.onOpenCv,
    required this.onReview,
    required this.onPlanInterview,
    required this.onAccept,
    required this.onReject,
  });

  String _candidateInitial(String value) {
    if (value.trim().isEmpty) return '?';
    return value.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final candidateName = application.candidateName.trim().isNotEmpty
        ? application.candidateName
        : application.candidateId;

    final hasCv = application.candidateCvUrl.trim().isNotEmpty;
    final status = application.status;
    final isFinal = status == 'accepted' || status == 'rejected';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  _candidateInitial(candidateName),
                  style: const TextStyle(
                    fontSize: 23,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (application.candidateEmail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        application.candidateEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.58),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(
                label: statusLabel(status),
                color: statusColor(status),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenProfile,
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('Profil'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasCv ? onOpenCv : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(hasCv ? 'CV' : 'Sans CV'),
                ),
              ),
            ],
          ),
          if (hasCv && application.candidateCvFileName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              application.candidateCvFileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.48),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (isFinal)
            _FinalStatusNotice(
              status: status,
              statusLabel: statusLabel(status),
              statusColor: statusColor(status),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReview,
                        icon: const Icon(Icons.manage_search_outlined),
                        label: const Text('Analyse'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPlanInterview,
                        icon: const Icon(Icons.event_available_outlined),
                        label: const Text('Planifier'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check),
                        label: const Text('Accepter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.52)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FinalStatusNotice extends StatelessWidget {
  final String status;
  final String statusLabel;
  final Color statusColor;

  const _FinalStatusNotice({
    required this.status,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final message = status == 'accepted'
        ? 'Cette candidature a été acceptée.'
        : 'Cette candidature a été refusée.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            status == 'accepted'
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmActionSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmActionSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 10, 22, bottomPadding + 22),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1627),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.45)),
            ),
            child: Icon(icon, color: iconColor, size: 31),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Colors.white.withOpacity(0.62),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _InfoSheet({
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
        color: Color(0xFF0E1627),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.45)),
            ),
            child: Icon(icon, color: iconColor, size: 31),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Colors.white.withOpacity(0.62),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Compris',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  final String jobTitle;

  const _EmptyApplications({required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 58,
              color: Colors.white.withOpacity(0.42),
            ),
            const SizedBox(height: 14),
            Text(
              'Aucune candidature reçue',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune candidature reçue pour l’offre "$jobTitle".',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredApplications extends StatelessWidget {
  final String label;

  const _EmptyFilteredApplications({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.64),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
