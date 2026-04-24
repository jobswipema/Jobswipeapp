import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/verification_status.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:jobswipe/features/company/presentation/create_job_page.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    final isVerified = user.isVerifiedCompany;
    final verificationStatus = user.verificationStatus;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161D2E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.business, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 20,
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut de vérification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isVerified
                        ? 'Votre entreprise a été validée par l’administrateur. Vous pouvez désormais publier vos offres d’emploi.'
                        : 'Votre entreprise doit être validée par un administrateur après vérification de son existence légale et signature du contrat. Tant que cette validation n’est pas effectuée, la publication d’offres reste désactivée.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
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
            if (!isVerified)
              const Text(
                'Action indisponible : votre compte entreprise est en cours de validation par l’administrateur.',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (isVerified)
              const Text(
                'Votre entreprise est validée. Vous pouvez publier vos offres.',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 28),
            const Text(
              'Aperçu dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Offres',
                    value: isVerified ? '4' : '0',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Candidatures',
                    value: isVerified ? '18' : '0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _StatCard(title: 'Vues totales', value: isVerified ? '1 284' : '0'),
          ],
        ),
      ),
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
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
