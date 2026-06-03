import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedTab = 0;

  Future<void> _confirmCompanyStatusUpdate({
    required BuildContext context,
    required String userId,
    required String status,
    required String companyName,
  }) async {
    String title;
    String message;
    String confirmLabel;

    if (status == 'approved') {
      title = 'Valider l’entreprise';
      message =
          'Confirmez-vous la validation de "$companyName" ? Cette entreprise pourra publier des offres.';
      confirmLabel = 'Valider';
    } else if (status == 'rejected') {
      title = 'Refuser l’entreprise';
      message =
          'Confirmez-vous le refus de "$companyName" ? Cette entreprise ne pourra pas publier d’offres.';
      confirmLabel = 'Refuser';
    } else {
      title = 'Remettre en attente';
      message =
          'Confirmez-vous la remise en attente de "$companyName" ? L’entreprise devra être validée à nouveau.';
      confirmLabel = 'Confirmer';
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

    await _updateCompanyStatus(
      context: context,
      userId: userId,
      status: status,
    );
  }

  Future<void> _updateCompanyStatus({
    required BuildContext context,
    required String userId,
    required String status,
  }) async {
    final isApproved = status == 'approved';

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'verificationStatus': status,
      'isVerifiedCompany': isApproved,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    String title;
    String message;

    if (status == 'approved') {
      title = 'Entreprise validée';
      message =
          'Votre compte entreprise a été validé. Vous pouvez maintenant publier des offres sur JobSwipe.';
    } else if (status == 'rejected') {
      title = 'Validation refusée';
      message =
          'La validation de votre compte entreprise a été refusée. Veuillez vérifier vos informations ou contacter l’administrateur.';
    } else {
      title = 'Validation en attente';
      message =
          'Votre compte entreprise a été remis en attente de validation par l’administrateur.';
    }

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': 'company_verification',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'approved'
              ? 'Entreprise validée avec succès.'
              : status == 'rejected'
              ? 'Entreprise refusée.'
              : 'Entreprise remise en attente.',
        ),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _jobsStream() {
    return FirebaseFirestore.instance.collection('jobs').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _applicationsStream() {
    return FirebaseFirestore.instance.collection('applications').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _interviewsStream() {
    return FirebaseFirestore.instance.collection('interviews').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: authNotifier.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _usersStream(),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.hasError) {
              return const Center(
                child: Text('Erreur lors du chargement des utilisateurs.'),
              );
            }

            if (!usersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _jobsStream(),
              builder: (context, jobsSnapshot) {
                if (jobsSnapshot.hasError) {
                  return const Center(
                    child: Text('Erreur lors du chargement des offres.'),
                  );
                }

                if (!jobsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _applicationsStream(),
                  builder: (context, applicationsSnapshot) {
                    if (applicationsSnapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Erreur lors du chargement des candidatures.',
                        ),
                      );
                    }

                    if (!applicationsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _interviewsStream(),
                      builder: (context, interviewsSnapshot) {
                        if (interviewsSnapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Erreur lors du chargement des entretiens.',
                            ),
                          );
                        }

                        if (!interviewsSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final users = usersSnapshot.data!.docs;
                        final jobs = jobsSnapshot.data!.docs;
                        final applications = applicationsSnapshot.data!.docs;
                        final interviews = interviewsSnapshot.data!.docs;

                        final candidates = users.where((doc) {
                          final data = doc.data();
                          return data['role']?.toString() == 'candidate';
                        }).toList();

                        final companies = users.where((doc) {
                          final data = doc.data();
                          return data['role']?.toString() == 'company';
                        }).toList();

                        final pendingCompanies = companies.where((doc) {
                          final data = doc.data();
                          return data['verificationStatus']?.toString() ==
                              'pending';
                        }).toList();

                        final approvedCompanies = companies.where((doc) {
                          final data = doc.data();
                          return data['verificationStatus']?.toString() ==
                                  'approved' ||
                              data['isVerifiedCompany'] == true;
                        }).toList();

                        final rejectedCompanies = companies.where((doc) {
                          final data = doc.data();
                          return data['verificationStatus']?.toString() ==
                              'rejected';
                        }).toList();

                        final activeJobs = jobs.where((doc) {
                          final data = doc.data();
                          return data['isActive'] == true;
                        }).toList();

                        final acceptedApplications = applications.where((doc) {
                          final data = doc.data();
                          return data['status']?.toString() == 'accepted';
                        }).toList();

                        final stats = _AdminStats(
                          usersCount: users.length,
                          candidatesCount: candidates.length,
                          companiesCount: companies.length,
                          pendingCompaniesCount: pendingCompanies.length,
                          approvedCompaniesCount: approvedCompanies.length,
                          rejectedCompaniesCount: rejectedCompanies.length,
                          jobsCount: jobs.length,
                          activeJobsCount: activeJobs.length,
                          applicationsCount: applications.length,
                          interviewsCount: interviews.length,
                          acceptedApplicationsCount:
                              acceptedApplications.length,
                        );

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AdminHeader(
                                adminName: 'Administrateur',
                                pendingCompaniesCount: pendingCompanies.length,
                              ),
                              const SizedBox(height: 18),
                              _AdminStatsGrid(stats: stats),
                              const SizedBox(height: 18),
                              _AdminTabs(
                                selectedIndex: _selectedTab,
                                onChanged: (index) {
                                  setState(() => _selectedTab = index);
                                },
                              ),
                              const SizedBox(height: 18),
                              if (_selectedTab == 0)
                                _DashboardTab(stats: stats)
                              else if (_selectedTab == 1)
                                _CompaniesTab(
                                  companies: companies,
                                  onApprove: (userId, companyName) {
                                    _confirmCompanyStatusUpdate(
                                      context: context,
                                      userId: userId,
                                      status: 'approved',
                                      companyName: companyName,
                                    );
                                  },
                                  onReject: (userId, companyName) {
                                    _confirmCompanyStatusUpdate(
                                      context: context,
                                      userId: userId,
                                      status: 'rejected',
                                      companyName: companyName,
                                    );
                                  },
                                  onPending: (userId, companyName) {
                                    _confirmCompanyStatusUpdate(
                                      context: context,
                                      userId: userId,
                                      status: 'pending',
                                      companyName: companyName,
                                    );
                                  },
                                )
                              else if (_selectedTab == 2)
                                _JobsTab(jobs: jobs, applications: applications)
                              else
                                _AnalyticsTab(
                                  users: users,
                                  jobs: jobs,
                                  applications: applications,
                                  interviews: interviews,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AdminStats {
  final int usersCount;
  final int candidatesCount;
  final int companiesCount;
  final int pendingCompaniesCount;
  final int approvedCompaniesCount;
  final int rejectedCompaniesCount;
  final int jobsCount;
  final int activeJobsCount;
  final int applicationsCount;
  final int interviewsCount;
  final int acceptedApplicationsCount;

  const _AdminStats({
    required this.usersCount,
    required this.candidatesCount,
    required this.companiesCount,
    required this.pendingCompaniesCount,
    required this.approvedCompaniesCount,
    required this.rejectedCompaniesCount,
    required this.jobsCount,
    required this.activeJobsCount,
    required this.applicationsCount,
    required this.interviewsCount,
    required this.acceptedApplicationsCount,
  });
}

class _AdminHeader extends StatelessWidget {
  final String adminName;
  final int pendingCompaniesCount;

  const _AdminHeader({
    required this.adminName,
    required this.pendingCompaniesCount,
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
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pendingCompaniesCount == 0
                      ? 'Aucune entreprise en attente'
                      : '$pendingCompaniesCount entreprise(s) en attente de validation',
                  style: TextStyle(
                    color: pendingCompaniesCount == 0
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                    fontWeight: FontWeight.w700,
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

class _AdminTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _AdminTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.business_outlined, 'Entreprises'),
      (Icons.work_outline, 'Offres'),
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
                        fontSize: 10,
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

class _AdminStatsGrid extends StatelessWidget {
  final _AdminStats stats;

  const _AdminStatsGrid({required this.stats});

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
          title: 'Candidats',
          value: stats.candidatesCount.toString(),
          icon: Icons.person_outline,
          color: Colors.greenAccent,
        ),
        _StatCard(
          title: 'Entreprises',
          value: stats.companiesCount.toString(),
          icon: Icons.business_outlined,
          color: Colors.blueAccent,
        ),
        _StatCard(
          title: 'En attente',
          value: stats.pendingCompaniesCount.toString(),
          icon: Icons.watch_later_outlined,
          color: Colors.amberAccent,
        ),
        _StatCard(
          title: 'Offres actives',
          value: stats.activeJobsCount.toString(),
          icon: Icons.work_outline,
          color: Colors.purpleAccent,
        ),
      ],
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final _AdminStats stats;

  const _DashboardTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Vue globale plateforme',
          icon: Icons.insights_outlined,
          children: [
            _MetricLine(label: 'Utilisateurs', value: stats.usersCount),
            _MetricLine(label: 'Candidats', value: stats.candidatesCount),
            _MetricLine(label: 'Entreprises', value: stats.companiesCount),
            _MetricLine(
              label: 'Entreprises vérifiées',
              value: stats.approvedCompaniesCount,
            ),
            _MetricLine(
              label: 'Entreprises en attente',
              value: stats.pendingCompaniesCount,
            ),
            _MetricLine(
              label: 'Entreprises refusées',
              value: stats.rejectedCompaniesCount,
            ),
            _MetricLine(label: 'Offres publiées', value: stats.jobsCount),
            _MetricLine(label: 'Offres actives', value: stats.activeJobsCount),
            _MetricLine(label: 'Candidatures', value: stats.applicationsCount),
            _MetricLine(label: 'Entretiens', value: stats.interviewsCount),
            _MetricLine(
              label: 'Recrutements acceptés',
              value: stats.acceptedApplicationsCount,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompaniesTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> companies;
  final void Function(String userId, String companyName) onApprove;
  final void Function(String userId, String companyName) onReject;
  final void Function(String userId, String companyName) onPending;

  const _CompaniesTab({
    required this.companies,
    required this.onApprove,
    required this.onReject,
    required this.onPending,
  });

  @override
  State<_CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<_CompaniesTab> {
  String _searchQuery = '';
  String _filter = 'all';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredCompanies {
    final query = _searchQuery.trim().toLowerCase();

    return widget.companies.where((doc) {
      final data = doc.data();

      final name = data['displayName']?.toString().toLowerCase() ?? '';
      final email = data['email']?.toString().toLowerCase() ?? '';
      final status = data['verificationStatus']?.toString() ?? 'pending';

      final matchesSearch =
          query.isEmpty || name.contains(query) || email.contains(query);

      final matchesFilter = switch (_filter) {
        'pending' => status == 'pending',
        'approved' => status == 'approved' || data['isVerifiedCompany'] == true,
        'rejected' => status == 'rejected',
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final companies = _filteredCompanies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchField(
          hintText: 'Rechercher une entreprise...',
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        const SizedBox(height: 12),
        _AdminFilters(
          selectedFilter: _filter,
          filters: const [
            ('all', 'Toutes'),
            ('pending', 'En attente'),
            ('approved', 'Validées'),
            ('rejected', 'Refusées'),
          ],
          onChanged: (value) {
            setState(() => _filter = value);
          },
        ),
        const SizedBox(height: 14),
        Text(
          '${companies.length} entreprise(s)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (companies.isEmpty)
          const _InfoCard(text: 'Aucune entreprise ne correspond au filtre.')
        else
          Column(
            children: companies.map((doc) {
              final data = doc.data();

              return _CompanyAdminCard(
                userId: doc.id,
                name: data['displayName']?.toString() ?? 'Entreprise',
                email: data['email']?.toString() ?? '',
                status: data['verificationStatus']?.toString() ?? 'pending',
                isVerified: data['isVerifiedCompany'] == true,
                onApprove: widget.onApprove,
                onReject: widget.onReject,
                onPending: widget.onPending,
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _JobsTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> jobs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> applications;

  const _JobsTab({required this.jobs, required this.applications});

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  String _searchQuery = '';
  String _filter = 'all';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredJobs {
    final query = _searchQuery.trim().toLowerCase();

    return widget.jobs.where((doc) {
      final data = doc.data();

      final title = data['title']?.toString().toLowerCase() ?? '';
      final companyName = data['companyName']?.toString().toLowerCase() ?? '';
      final location = data['location']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          title.contains(query) ||
          companyName.contains(query) ||
          location.contains(query);

      final isActive = data['isActive'] == true;

      final matchesFilter = switch (_filter) {
        'active' => isActive,
        'inactive' => !isActive,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _applicationsCount(String jobId) {
    return widget.applications.where((doc) {
      final data = doc.data();
      return data['jobId']?.toString() == jobId;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _filteredJobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchField(
          hintText: 'Rechercher une offre...',
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        const SizedBox(height: 12),
        _AdminFilters(
          selectedFilter: _filter,
          filters: const [
            ('all', 'Toutes'),
            ('active', 'Actives'),
            ('inactive', 'Inactives'),
          ],
          onChanged: (value) {
            setState(() => _filter = value);
          },
        ),
        const SizedBox(height: 14),
        Text(
          '${jobs.length} offre(s)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          const _InfoCard(text: 'Aucune offre ne correspond au filtre.')
        else
          Column(
            children: jobs.map((doc) {
              final data = doc.data();

              return _JobAdminRow(
                title: data['title']?.toString() ?? 'Offre sans titre',
                companyName:
                    data['companyName']?.toString() ?? 'Entreprise inconnue',
                location: data['location']?.toString() ?? '',
                isActive: data['isActive'] == true,
                viewsCount: _toInt(data['viewsCount']),
                applicationsCount: _applicationsCount(doc.id),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> users;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> jobs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> applications;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> interviews;

  const _AnalyticsTab({
    required this.users,
    required this.jobs,
    required this.applications,
    required this.interviews,
  });

  @override
  Widget build(BuildContext context) {
    final totalViews = jobs.fold<int>(0, (sum, doc) {
      return sum + _toInt(doc.data()['viewsCount']);
    });

    final totalFavorites = jobs.fold<int>(0, (sum, doc) {
      return sum + _toInt(doc.data()['favoritesCount']);
    });

    final totalApplications = applications.length;

    final conversionRate = totalViews == 0
        ? 0
        : (totalApplications / totalViews) * 100;

    final submitted = applications.where((doc) {
      return doc.data()['status']?.toString() == 'submitted';
    }).length;

    final reviewing = applications.where((doc) {
      return doc.data()['status']?.toString() == 'reviewing';
    }).length;

    final interview = applications.where((doc) {
      return doc.data()['status']?.toString() == 'interview';
    }).length;

    final accepted = applications.where((doc) {
      return doc.data()['status']?.toString() == 'accepted';
    }).length;

    final rejected = applications.where((doc) {
      return doc.data()['status']?.toString() == 'rejected';
    }).length;

    return Column(
      children: [
        _SectionCard(
          title: 'Engagement global',
          icon: Icons.trending_up,
          children: [
            _MetricLine(label: 'Vues totales', value: totalViews),
            _MetricLine(label: 'Favoris', value: totalFavorites),
            _MetricLine(label: 'Candidatures', value: totalApplications),
            _MetricLine(
              label: 'Taux candidature / vues',
              valueText: '${conversionRate.toStringAsFixed(1)}%',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Funnel global',
          icon: Icons.account_tree_outlined,
          children: [
            _MetricLine(label: 'Reçues', value: submitted),
            _MetricLine(label: 'En analyse', value: reviewing),
            _MetricLine(label: 'Entretien', value: interview),
            _MetricLine(label: 'Acceptées', value: accepted),
            _MetricLine(label: 'Refusées', value: rejected),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Activité plateforme',
          icon: Icons.data_usage_outlined,
          children: [
            _MetricLine(label: 'Utilisateurs', value: users.length),
            _MetricLine(label: 'Offres', value: jobs.length),
            _MetricLine(label: 'Entretiens', value: interviews.length),
          ],
        ),
      ],
    );
  }
}

class _CompanyAdminCard extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String status;
  final bool isVerified;
  final void Function(String userId, String companyName) onApprove;
  final void Function(String userId, String companyName) onReject;
  final void Function(String userId, String companyName) onPending;

  const _CompanyAdminCard({
    required this.userId,
    required this.name,
    required this.email,
    required this.status,
    required this.isVerified,
    required this.onApprove,
    required this.onReject,
    required this.onPending,
  });

  Color get _statusColor {
    if (status == 'approved' || isVerified) return Colors.greenAccent;
    if (status == 'rejected') return Colors.redAccent;
    return Colors.amberAccent;
  }

  String get _statusLabel {
    if (status == 'approved' || isVerified) return 'Validée';
    if (status == 'rejected') return 'Refusée';
    return 'En attente';
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = status == 'approved' || isVerified;
    final isRejected = status == 'rejected';

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
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.business, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.58),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 14),
          if (!isApproved)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => onApprove(userId, name),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Valider'),
              ),
            ),
          if (!isApproved) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isRejected ? null : () => onReject(userId, name),
                  icon: const Icon(Icons.close),
                  label: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status == 'pending'
                      ? null
                      : () => onPending(userId, name),
                  icon: const Icon(Icons.watch_later_outlined),
                  label: const Text('Attente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobAdminRow extends StatelessWidget {
  final String title;
  final String companyName;
  final String location;
  final bool isActive;
  final int viewsCount;
  final int applicationsCount;

  const _JobAdminRow({
    required this.title,
    required this.companyName,
    required this.location,
    required this.isActive,
    required this.viewsCount,
    required this.applicationsCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  location.trim().isEmpty
                      ? companyName
                      : '$companyName • $location',
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
                      label: '$viewsCount',
                    ),
                    _StatusPill(
                      label: isActive ? 'Active' : 'Inactive',
                      color: color,
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

class _SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
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

class _AdminFilters extends StatelessWidget {
  final String selectedFilter;
  final List<(String, String)> filters;
  final ValueChanged<String> onChanged;

  const _AdminFilters({
    required this.selectedFilter,
    required this.filters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final value = filter.$1;
        final label = filter.$2;
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
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
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
  final int? value;
  final String? valueText;

  const _MetricLine({required this.label, this.value, this.valueText});

  @override
  Widget build(BuildContext context) {
    final displayValue = valueText ?? value?.toString() ?? '-';

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
            displayValue,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
