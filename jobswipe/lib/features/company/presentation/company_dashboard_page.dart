import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/verification_status.dart';
import 'package:jobswipe/features/company/data/company_dashboard_provider.dart';
import 'package:jobswipe/features/company/presentation/company_applications_page.dart';
import 'package:jobswipe/features/company/presentation/create_job_page.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/models/job_offer.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    final isVerified = user.isVerifiedCompany;
    final verificationStatus = user.verificationStatus;

    final jobsAsync = ref.watch(companyJobsProvider(user.id));
    final applicationsAsync = ref.watch(companyApplicationsProvider(user.id));

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyHeader(
                companyName: user.displayName,
                statusText: statusText,
                statusColor: statusColor,
                statusIcon: statusIcon,
              ),

              const SizedBox(height: 22),

              _VerificationCard(isVerified: isVerified),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: isVerified
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateJobPage(),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Ajouter une offre'),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                isVerified
                    ? 'Votre entreprise est validée. Vous pouvez publier vos offres.'
                    : 'Action indisponible : votre compte entreprise est en cours de validation par l’administrateur.',
                style: TextStyle(
                  color: isVerified ? Colors.greenAccent : Colors.amber,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Tableau de bord',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

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
                      final totalApplications = applications.length;
                      final activeJobs = jobs
                          .where((job) => job.isActive)
                          .length;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Offres publiées',
                                  value: jobs.length.toString(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Offres actives',
                                  value: activeJobs.toString(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            title: 'Candidatures reçues',
                            value: totalApplications.toString(),
                          ),
                          const SizedBox(height: 28),
                          _JobsList(jobs: jobs, applications: applications),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
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
                  companyName,
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
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2337),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVerified ? Colors.greenAccent : Colors.amber,
          width: 0.6,
        ),
      ),
      child: Text(
        isVerified
            ? 'Votre entreprise a été validée par l’administrateur. Vous pouvez désormais publier vos offres d’emploi et consulter les candidatures reçues.'
            : 'Votre entreprise doit être validée par un administrateur après vérification de son existence légale et signature du contrat. Tant que cette validation n’est pas effectuée, la publication d’offres reste désactivée.',
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.white.withOpacity(0.75),
        ),
      ),
    );
  }
}

class _JobsList extends StatelessWidget {
  final List<JobOffer> jobs;
  final List<ApplicationModel> applications;

  const _JobsList({required this.jobs, required this.applications});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161D2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Aucune offre publiée pour le moment.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes offres',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        ...jobs.map((job) {
          final jobApplications = applications
              .where((app) => app.jobId == job.id)
              .toList();

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
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${job.location} • ${job.contractType} • ${job.experience}',
                  style: TextStyle(color: Colors.white.withOpacity(0.68)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniPill(
                      label: '${jobApplications.length} candidature(s)',
                      icon: Icons.people_outline,
                    ),
                    const SizedBox(width: 8),
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
                          builder: (context) =>
                              CompanyApplicationsPage(job: job),
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
        }).toList(),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
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
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2B),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
