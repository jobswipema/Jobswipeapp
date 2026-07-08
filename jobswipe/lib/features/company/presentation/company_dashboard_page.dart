import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/verification_status.dart';
import 'package:jobswipe/features/company/data/company_dashboard_provider.dart';
import 'package:jobswipe/features/company/presentation/company_applications_page.dart';
import 'package:jobswipe/features/company/presentation/company_interviews_page.dart';
import 'package:jobswipe/features/company/presentation/create_job_page.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:jobswipe/features/company/presentation/company_notifications_page.dart';
import 'package:jobswipe/features/company/presentation/company_talents_feed_page.dart';

class CompanyDashboardPage extends ConsumerStatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  ConsumerState<CompanyDashboardPage> createState() =>
      _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends ConsumerState<CompanyDashboardPage> {
  int _selectedTab = 0;

  Stream<QuerySnapshot<Map<String, dynamic>>> _interviewsStream(
    String companyId,
  ) {
    return FirebaseFirestore.instance
        .collection('interviews')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    final jobsAsync = ref.watch(companyJobsProvider(user.id));
    final applicationsAsync = ref.watch(companyApplicationsProvider(user.id));

    final verificationStatus = user.verificationStatus;
    final isVerified = user.isVerifiedCompany;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (verificationStatus) {
      case VerificationStatus.approved:
        statusText = 'Entreprise vérifiée';
        statusColor = Colors.greenAccent;
        statusIcon = Icons.verified;
        break;
      case VerificationStatus.rejected:
        statusText = 'Validation refusée';
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_outlined;
        break;
      case VerificationStatus.pending:
      default:
        statusText = 'Validation en attente';
        statusColor = Colors.amber;
        statusIcon = Icons.watch_later_outlined;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Entreprise'),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user.id)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CompanyNotificationsPage(companyId: user.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: authNotifier.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _interviewsStream(user.id),
          builder: (context, interviewsSnapshot) {
            final interviewsCount = interviewsSnapshot.data?.docs.length ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyHeader(
                    companyName: user.displayName,
                    statusText: statusText,
                    statusColor: statusColor,
                    statusIcon: statusIcon,
                  ),
                  const SizedBox(height: 18),

                  applicationsAsync.when(
                    loading: () => const _DashboardLoading(),
                    error: (error, _) => _ErrorCard(
                      message: 'Erreur chargement candidatures : $error',
                    ),
                    data: (applications) {
                      return jobsAsync.when(
                        loading: () => const _DashboardLoading(),
                        error: (error, _) => _ErrorCard(
                          message: 'Erreur chargement offres : $error',
                        ),
                        data: (jobs) {
                          final activeJobs = jobs
                              .where((job) => job.isActive)
                              .length;

                          final totalApplications = applications.length;

                          final totalViews = jobs.fold<int>(
                            0,
                            (sum, job) => sum + job.viewsCount,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StatsGrid(
                                activeJobs: activeJobs,
                                totalApplications: totalApplications,
                                interviewsCount: interviewsCount,
                                totalViews: totalViews,
                              ),
                              const SizedBox(height: 18),
                              _CompanyTabs(
                                selectedIndex: _selectedTab,
                                onChanged: (index) {
                                  if (index == 2) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CompanyTalentsFeedPage(),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _selectedTab = index);
                                },
                              ),
                              const SizedBox(height: 18),

                              if (_selectedTab == 0)
                                _DashboardTab(
                                  isVerified: isVerified,
                                  jobs: jobs,
                                  applications: applications,
                                )
                              else if (_selectedTab == 1)
                                _OffersTab(
                                  isVerified: isVerified,
                                  jobs: jobs,
                                  applications: applications,
                                )
                              else if (_selectedTab == 3)
                                const _InterviewsTab()
                              else
                                _AnalyticsTab(
                                  jobs: jobs,
                                  applications: applications,
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompanyTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _CompanyTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.work_outline, 'Offres'),
      (Icons.video_library_outlined, 'Talents'),
      (Icons.event_available_outlined, 'Entretiens'),
      (Icons.analytics_outlined, 'Analytics'),
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
                        fontSize: 9,
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

class _DashboardTab extends StatelessWidget {
  final bool isVerified;
  final List<JobOffer> jobs;
  final List<ApplicationModel> applications;

  const _DashboardTab({
    required this.isVerified,
    required this.jobs,
    required this.applications,
  });

  @override
  Widget build(BuildContext context) {
    final received = applications.where((a) => a.status == 'submitted').length;
    final reviewing = applications.where((a) => a.status == 'reviewing').length;
    final interview = applications.where((a) => a.status == 'interview').length;
    final accepted = applications.where((a) => a.status == 'accepted').length;
    final rejected = applications.where((a) => a.status == 'rejected').length;

    return Column(
      children: [
        _VerificationCard(isVerified: isVerified),
        const SizedBox(height: 14),
        _AnalyticsCard(
          title: 'Résumé recrutement',
          icon: Icons.insights_outlined,
          children: [
            _MetricLine(
              label: 'Offres publiées',
              value: jobs.length.toString(),
            ),
            _MetricLine(
              label: 'Candidatures reçues',
              value: applications.length.toString(),
            ),
            _MetricLine(label: 'Reçues', value: received.toString()),
            _MetricLine(label: 'En analyse', value: reviewing.toString()),
            _MetricLine(label: 'En entretien', value: interview.toString()),
            _MetricLine(label: 'Acceptées', value: accepted.toString()),
            _MetricLine(label: 'Refusées', value: rejected.toString()),
          ],
        ),
      ],
    );
  }
}

class _OffersTab extends StatefulWidget {
  final bool isVerified;
  final List<JobOffer> jobs;
  final List<ApplicationModel> applications;

  const _OffersTab({
    required this.isVerified,
    required this.jobs,
    required this.applications,
  });

  @override
  State<_OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends State<_OffersTab> {
  String _searchQuery = '';
  String _filter = 'all';

  List<JobOffer> get _filteredJobs {
    final query = _searchQuery.trim().toLowerCase();

    return widget.jobs.where((job) {
      final matchesSearch =
          query.isEmpty ||
          job.title.toLowerCase().contains(query) ||
          job.location.toLowerCase().contains(query) ||
          job.contractType.toLowerCase().contains(query) ||
          job.experience.toLowerCase().contains(query);

      final matchesFilter = switch (_filter) {
        'active' => job.isActive,
        'inactive' => !job.isActive,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _applicationsCount(String jobId) {
    return widget.applications.where((app) => app.jobId == jobId).length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _filteredJobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactCreateOfferButton(isVerified: widget.isVerified),
        const SizedBox(height: 14),

        _OfferSearchField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        const SizedBox(height: 12),

        _OfferFilters(
          selectedFilter: _filter,
          onChanged: (value) {
            setState(() => _filter = value);
          },
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Text(
                '${filteredJobs.length} offre(s)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${widget.jobs.length} au total',
              style: TextStyle(
                color: Colors.white.withOpacity(0.42),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (widget.jobs.isEmpty)
          const _InfoCard(text: 'Aucune offre publiée pour le moment.')
        else if (filteredJobs.isEmpty)
          const _InfoCard(text: 'Aucune offre ne correspond à votre recherche.')
        else
          Column(
            children: filteredJobs.map((job) {
              return _CompactJobRow(
                job: job,
                applicationsCount: _applicationsCount(job.id),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _CompactCreateOfferButton extends StatelessWidget {
  final bool isVerified;

  const _CompactCreateOfferButton({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isVerified
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateJobPage()),
                );
              }
            : null,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Publier une offre'),
      ),
    );
  }
}

class _OfferSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _OfferSearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Rechercher une offre...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFF161D2E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.70)),
        ),
      ),
    );
  }
}

class _OfferFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _OfferFilters({required this.selectedFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipButton(
          label: 'Toutes',
          value: 'all',
          selectedFilter: selectedFilter,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        _FilterChipButton(
          label: 'Actives',
          value: 'active',
          selectedFilter: selectedFilter,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        _FilterChipButton(
          label: 'Inactives',
          value: 'inactive',
          selectedFilter: selectedFilter,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final String value;
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _FilterChipButton({
    required this.label,
    required this.value,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.18)
              : const Color(0xFF161D2E),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent.withOpacity(0.75)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CompactJobRow extends StatelessWidget {
  final JobOffer job;
  final int applicationsCount;

  const _CompactJobRow({required this.job, required this.applicationsCount});

  Future<void> _showCompanyDashboardSheet({
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
        return _CompanyDashboardInfoBottomSheet(
          icon: icon,
          iconColor: iconColor,
          title: title,
          message: message,
        );
      },
    );
  }

  Future<void> _updateJobStatus({
    required BuildContext context,
    required String jobId,
    required String action,
  }) async {
    String title;
    String message;
    String confirmLabel;

    if (action == 'pause') {
      title = 'Désactiver l’offre';
      message =
          'Confirmez-vous la désactivation de cette offre ? Elle ne sera plus visible par les candidats.';
      confirmLabel = 'Désactiver';
    } else if (action == 'open') {
      title = 'Réactiver l’offre';
      message =
          'Confirmez-vous la réactivation de cette offre ? Elle sera à nouveau visible par les candidats.';
      confirmLabel = 'Réactiver';
    } else if (action == 'close') {
      title = 'Clôturer le recrutement';
      message =
          'Confirmez-vous la clôture de cette offre ? Elle ne sera plus visible et sera marquée comme recrutement terminé.';
      confirmLabel = 'Clôturer';
    } else {
      title = 'Supprimer l’offre';
      message =
          'Confirmez-vous la suppression définitive de cette offre ? Cette action est irréversible.';
      confirmLabel = 'Supprimer';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    if (action == 'delete') {
      if (applicationsCount > 0) {
        await _showCompanyDashboardSheet(
          context: context,
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber,
          title: 'Suppression impossible',
          message:
              'Impossible de supprimer une offre ayant déjà des candidatures. Vous pouvez la désactiver ou la clôturer.',
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();

        if (!context.mounted) return;

        await _showCompanyDashboardSheet(
          context: context,
          icon: Icons.delete_outline,
          iconColor: Colors.greenAccent,
          title: 'Offre supprimée',
          message: 'L’offre a été supprimée avec succès.',
        );
      } catch (e) {
        if (!context.mounted) return;

        await _showCompanyDashboardSheet(
          context: context,
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          title: 'Suppression impossible',
          message: 'Une erreur est survenue lors de la suppression : $e',
        );
      }

      return;
    }

    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (action == 'pause') {
      updateData['isActive'] = false;
      updateData['jobStatus'] = 'paused';
    }

    if (action == 'open') {
      updateData['isActive'] = true;
      updateData['jobStatus'] = 'open';
    }

    if (action == 'close') {
      updateData['isActive'] = false;
      updateData['jobStatus'] = 'closed';
      updateData['closedAt'] = FieldValue.serverTimestamp();
      updateData['closedReason'] = 'hired';
    }

    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .update(updateData);

      if (!context.mounted) return;

      await _showCompanyDashboardSheet(
        context: context,
        icon: Icons.check_circle_outline,
        iconColor: Colors.greenAccent,
        title: action == 'pause'
            ? 'Offre désactivée'
            : action == 'open'
            ? 'Offre réactivée'
            : 'Offre clôturée',
        message: action == 'pause'
            ? 'L’offre a été désactivée avec succès.'
            : action == 'open'
            ? 'L’offre a été réactivée avec succès.'
            : 'Le recrutement a été clôturé avec succès.',
      );
    } catch (e) {
      if (!context.mounted) return;

      await _showCompanyDashboardSheet(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        title: 'Mise à jour impossible',
        message: 'Une erreur est survenue lors de la mise à jour : $e',
      );
    }
  }

  Color _statusColor(String jobStatus, bool isActive) {
    if (jobStatus == 'closed') return Colors.purpleAccent;
    if (jobStatus == 'paused' || !isActive) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _statusLabel(String jobStatus, bool isActive) {
    if (jobStatus == 'closed') return 'Clôturée';
    if (jobStatus == 'paused' || !isActive) return 'Désactivée';
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final jobStatus = job.jobStatus.isEmpty
        ? (job.isActive ? 'open' : 'paused')
        : job.jobStatus;

    final statusColor = _statusColor(jobStatus, job.isActive);
    final statusLabel = _statusLabel(jobStatus, job.isActive);

    final canPause = jobStatus == 'open' && job.isActive;
    final canOpen =
        jobStatus == 'paused' || (!job.isActive && jobStatus != 'closed');
    final canClose = jobStatus != 'closed';
    final canDelete = applicationsCount == 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CompanyApplicationsPage(job: job)),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161D2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.work_outline, color: Colors.blueAccent),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${job.location} • ${job.contractType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      _SmallMetricPill(
                        icon: Icons.people_outline,
                        label: '$applicationsCount',
                      ),
                      _SmallMetricPill(
                        icon: Icons.visibility_outlined,
                        label: '${job.viewsCount}',
                      ),
                      _SmallMetricPill(
                        icon: Icons.bookmark_outline,
                        label: '${job.favoritesCount}',
                      ),
                      _SmallStatusPill(label: statusLabel, color: statusColor),
                    ],
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF161D2E),
              onSelected: (value) async {
                if (value == 'applications') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompanyApplicationsPage(job: job),
                    ),
                  );
                  return;
                }

                if (value == 'edit') {
                  await _showCompanyDashboardSheet(
                    context: context,
                    icon: Icons.edit_outlined,
                    iconColor: Colors.amber,
                    title: 'Modification indisponible',
                    message:
                        'La modification de l’offre sera ajoutée prochainement.',
                  );
                  return;
                }

                await _updateJobStatus(
                  context: context,
                  jobId: job.id,
                  action: value,
                );
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: 'applications',
                    child: Text('Voir les candidatures'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  if (canPause)
                    const PopupMenuItem(
                      value: 'pause',
                      child: Text('Désactiver'),
                    ),
                  if (canOpen)
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('Réactiver'),
                    ),
                  if (canClose)
                    const PopupMenuItem(
                      value: 'close',
                      child: Text('Clôturer recrutement'),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: canDelete,
                    child: Text(
                      canDelete ? 'Supprimer' : 'Supprimer impossible',
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyDashboardInfoBottomSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _CompanyDashboardInfoBottomSheet({
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

class _SmallMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallMetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SmallStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InterviewsTab extends StatelessWidget {
  const _InterviewsTab();

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      title: 'Entretiens planifiés',
      subtitle: 'Ouvrir le calendrier RH complet',
      icon: Icons.event_available_outlined,
      color: Colors.amberAccent,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CompanyInterviewsPage()),
        );
      },
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final List<JobOffer> jobs;
  final List<ApplicationModel> applications;

  const _AnalyticsTab({required this.jobs, required this.applications});

  @override
  Widget build(BuildContext context) {
    final totalApplications = applications.length;

    final totalViews = jobs.fold<int>(0, (sum, job) => sum + job.viewsCount);

    final totalLikes = jobs.fold<int>(0, (sum, job) => sum + job.likesCount);

    final totalFavorites = jobs.fold<int>(
      0,
      (sum, job) => sum + job.favoritesCount,
    );

    final conversionRate = totalViews == 0
        ? 0
        : ((totalApplications / totalViews) * 100);

    final received = applications.where((a) => a.status == 'submitted').length;
    final reviewing = applications.where((a) => a.status == 'reviewing').length;
    final interview = applications.where((a) => a.status == 'interview').length;
    final accepted = applications.where((a) => a.status == 'accepted').length;
    final rejected = applications.where((a) => a.status == 'rejected').length;

    final sortedJobs = [...jobs];
    sortedJobs.sort((a, b) {
      final aScore = a.viewsCount + a.applicationsCount * 5;
      final bScore = b.viewsCount + b.applicationsCount * 5;
      return bScore.compareTo(aScore);
    });

    final topJobs = sortedJobs.take(3).toList();

    return Column(
      children: [
        _AnalyticsCard(
          title: 'Engagement',
          icon: Icons.trending_up,
          children: [
            _MetricLine(label: 'Vues', value: totalViews.toString()),
            _MetricLine(label: 'Likes', value: totalLikes.toString()),
            _MetricLine(label: 'Favoris', value: totalFavorites.toString()),
            _MetricLine(
              label: 'Taux candidature / vues',
              value: '${conversionRate.toStringAsFixed(1)}%',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AnalyticsCard(
          title: 'Funnel recrutement',
          icon: Icons.account_tree_outlined,
          children: [
            _MetricLine(label: 'Reçues', value: received.toString()),
            _MetricLine(label: 'En analyse', value: reviewing.toString()),
            _MetricLine(label: 'Entretien', value: interview.toString()),
            _MetricLine(label: 'Acceptées', value: accepted.toString()),
            _MetricLine(label: 'Refusées', value: rejected.toString()),
          ],
        ),
        const SizedBox(height: 14),
        if (topJobs.isNotEmpty)
          _AnalyticsCard(
            title: 'Top offres',
            icon: Icons.emoji_events_outlined,
            children: topJobs.map((job) {
              final count = applications.where((a) => a.jobId == job.id).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JobPerformanceLine(
                  title: job.title,
                  views: job.viewsCount,
                  applications: count,
                  favorites: job.favoritesCount,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  final String companyName;
  final String statusText;
  final Color statusColor;
  final IconData statusIcon;

  const _CompanyHeader({
    required this.companyName,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = companyName.trim().isEmpty
        ? 'Entreprise'
        : companyName.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.business, color: Colors.white),
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
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int activeJobs;
  final int totalApplications;
  final int interviewsCount;
  final int totalViews;

  const _StatsGrid({
    required this.activeJobs,
    required this.totalApplications,
    required this.interviewsCount,
    required this.totalViews,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.38,
      children: [
        _StatCard(
          title: 'Offres actives',
          value: activeJobs.toString(),
          icon: Icons.work_outline,
          color: Colors.blueAccent,
        ),
        _StatCard(
          title: 'Candidatures',
          value: totalApplications.toString(),
          icon: Icons.people_outline,
          color: Colors.greenAccent,
        ),
        _StatCard(
          title: 'Entretiens',
          value: interviewsCount.toString(),
          icon: Icons.event_available,
          color: Colors.amberAccent,
        ),
        _StatCard(
          title: 'Vues totales',
          value: totalViews.toString(),
          icon: Icons.visibility_outlined,
          color: Colors.purpleAccent,
        ),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final bool isVerified;

  const _VerificationCard({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2337),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isVerified
              ? Colors.greenAccent.withOpacity(0.55)
              : Colors.amber.withOpacity(0.55),
        ),
      ),
      child: Text(
        isVerified
            ? 'Votre entreprise est validée. Vous pouvez publier vos offres et suivre vos indicateurs de recrutement.'
            : 'Votre entreprise doit être validée par un administrateur avant de publier des offres.',
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: Colors.white.withOpacity(0.75),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
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

class _JobCard extends StatelessWidget {
  final JobOffer job;
  final int applicationsCount;

  const _JobCard({required this.job, required this.applicationsCount});

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
          Text(
            job.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${job.location} • ${job.contractType} • ${job.experience}',
            style: TextStyle(color: Colors.white.withOpacity(0.68)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                label: '$applicationsCount candidature(s)',
                icon: Icons.people_outline,
              ),
              _MiniPill(
                label: '${job.viewsCount} vues',
                icon: Icons.visibility_outlined,
              ),
              _MiniPill(
                label: '${job.favoritesCount} favoris',
                icon: Icons.bookmark_outline,
              ),
              _MiniPill(
                label: job.isActive ? 'Active' : 'Inactive',
                icon: job.isActive
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CompanyApplicationsPage(job: job),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Voir les candidatures'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _AnalyticsCard({
    required this.title,
    required this.icon,
    required this.children,
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
          ...children,
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetricLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.68)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _JobPerformanceLine extends StatelessWidget {
  final String title;
  final int views;
  final int applications;
  final int favorites;

  const _JobPerformanceLine({
    required this.title,
    required this.views,
    required this.applications,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(label: '$views vues', icon: Icons.visibility_outlined),
              _MiniPill(
                label: '$applications candidatures',
                icon: Icons.people_outline,
              ),
              _MiniPill(
                label: '$favorites favoris',
                icon: Icons.bookmark_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
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
        border: Border.all(color: Colors.white10),
      ),
      child: Text(text),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.40)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.redAccent)),
    );
  }
}
