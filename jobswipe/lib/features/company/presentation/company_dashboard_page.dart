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

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _interviewsStream(
    String companyId,
  ) {
    return FirebaseFirestore.instance
        .collection('interviews')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const SizedBox(height: 16),
                  _VerificationCard(isVerified: isVerified),
                  const SizedBox(height: 22),

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
                              const Text(
                                'Vue rapide',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              GridView.count(
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
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Menu entreprise',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _MenuGrid(
                                isVerified: isVerified,
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

class _MenuGrid extends StatelessWidget {
  final bool isVerified;
  final List<JobOffer> jobs;
  final List<ApplicationModel> applications;

  const _MenuGrid({
    required this.isVerified,
    required this.jobs,
    required this.applications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuCard(
          title: 'Publier une offre',
          subtitle: 'Créer une nouvelle annonce vidéo',
          icon: Icons.add_business_outlined,
          color: Colors.blueAccent,
          enabled: isVerified,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CreateJobPage()));
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          title: 'Entretiens planifiés',
          subtitle: 'Voir le calendrier RH',
          icon: Icons.event_available,
          color: Colors.amberAccent,
          enabled: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompanyInterviewsPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          title: 'Mes offres',
          subtitle: 'Gérer les offres et candidatures',
          icon: Icons.work_outline,
          color: Colors.greenAccent,
          enabled: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CompanyJobsPage(jobs: jobs, applications: applications),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          title: 'Analytics détaillés',
          subtitle: 'Performance, funnel et engagement',
          icon: Icons.analytics_outlined,
          color: Colors.purpleAccent,
          enabled: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CompanyAnalyticsPage(
                  jobs: jobs,
                  applications: applications,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class CompanyJobsPage extends StatelessWidget {
  final List<JobOffer> jobs;
  final List<ApplicationModel> applications;

  const CompanyJobsPage({
    super.key,
    required this.jobs,
    required this.applications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes offres')),
      body: SafeArea(
        child: jobs.isEmpty
            ? const Center(child: Text('Aucune offre publiée pour le moment.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Text(
                    '${jobs.length} offre(s) publiée(s)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...jobs.map((job) {
                    final jobApplications = applications
                        .where((app) => app.jobId == job.id)
                        .toList();

                    return _JobCard(
                      job: job,
                      applicationsCount: jobApplications.length,
                    );
                  }),
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

class CompanyAnalyticsPage extends StatelessWidget {
  final List<JobOffer> jobs;
  final List<ApplicationModel> applications;

  const CompanyAnalyticsPage({
    super.key,
    required this.jobs,
    required this.applications,
  });

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

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text(
              'Performance recrutement',
              style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            if (topJobs.isNotEmpty)
              _AnalyticsCard(
                title: 'Top offres',
                icon: Icons.emoji_events_outlined,
                children: topJobs.map((job) {
                  final count = applications
                      .where((a) => a.jobId == job.id)
                      .length;

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
        ),
      ),
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

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: enabled ? onTap : null,
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
