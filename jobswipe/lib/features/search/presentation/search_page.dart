import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  String _query = '';
  String _selectedCity = 'Toutes';
  String _selectedContract = 'Tous';

  final List<String> _cities = const [
    'Toutes',
    'Casablanca',
    'Rabat',
    'Kenitra',
    'Marrakech',
    'Tanger',
    'Fès',
  ];

  final List<String> _contracts = const [
    'Tous',
    'CDI',
    'CDD',
    'Stage',
    'Freelance',
    'Alternance',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<JobOffer>> _jobsStream() {
    return FirebaseFirestore.instance
        .collection('jobs')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final jobs = snapshot.docs.map(JobOffer.fromFirestore).where((job) {
            final query = _query.trim().toLowerCase();

            final matchesQuery =
                query.isEmpty ||
                job.title.toLowerCase().contains(query) ||
                job.description.toLowerCase().contains(query) ||
                job.companyName.toLowerCase().contains(query) ||
                job.category.toLowerCase().contains(query);

            final matchesCity =
                _selectedCity == 'Toutes' ||
                job.location.toLowerCase() == _selectedCity.toLowerCase();

            final matchesContract =
                _selectedContract == 'Tous' ||
                job.contractType == _selectedContract;

            return matchesQuery && matchesCity && matchesContract;
          }).toList();

          jobs.sort((a, b) {
            final aDate = a.createdAt;
            final bDate = b.createdAt;

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;

            return bDate.compareTo(aDate);
          });

          return jobs;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<JobOffer>>(
          stream: _jobsStream(),
          builder: (context, snapshot) {
            final jobs = snapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECHERCHE',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Métier, entreprise, compétence...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFF161D2E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _FilterDropdown(
                                value: _selectedCity,
                                items: _cities,
                                icon: Icons.location_on_outlined,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedCity = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FilterDropdown(
                                value: _selectedContract,
                                items: _contracts,
                                icon: Icons.badge_outlined,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedContract = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '${jobs.length} offre(s) trouvée(s)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (snapshot.hasError)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text('Erreur lors du chargement des offres.'),
                    ),
                  )
                else if (!snapshot.hasData)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (jobs.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Aucune offre ne correspond à votre recherche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        return _SearchJobCard(job: jobs[index]);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchJobCard extends StatelessWidget {
  final JobOffer job;

  const _SearchJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${job.companyName} • ${job.location}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: job.contractType),
              _Pill(label: job.experience),
              _Pill(label: job.salary),
            ],
          ),
          if (job.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF161D2E),
      iconEnabledColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF161D2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
