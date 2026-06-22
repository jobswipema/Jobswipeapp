import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

class EditCandidateProfilePage extends ConsumerStatefulWidget {
  const EditCandidateProfilePage({super.key});

  @override
  ConsumerState<EditCandidateProfilePage> createState() =>
      _EditCandidateProfilePageState();
}

class _EditCandidateProfilePageState
    extends ConsumerState<EditCandidateProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _titleController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authProvider);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .get();

    final data = doc.data() ?? {};

    final skillsRaw = data['skills'];
    final skills = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).join(', ')
        : '';

    _displayNameController.text =
        data['displayName']?.toString() ?? user.displayName;
    _titleController.text = data['title']?.toString() ?? '';
    _cityController.text = data['city']?.toString() ?? '';
    _phoneController.text = data['phone']?.toString() ?? '';
    _bioController.text = data['bio']?.toString() ?? '';
    _skillsController.text = skills;
    _linkedinController.text = data['linkedinUrl']?.toString() ?? '';
    _githubController.text = data['githubUrl']?.toString() ?? '';
    _portfolioController.text = data['portfolioUrl']?.toString() ?? '';

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFF1A2235),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.2),
      ),
    );
  }

  List<String> _parseSkills(String value) {
    return value
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toSet()
        .toList();
  }

  int _calculateProfileCompletion({
    required String displayName,
    required String title,
    required String city,
    required String phone,
    required String bio,
    required List<String> skills,
  }) {
    var score = 0;

    if (displayName.trim().isNotEmpty) score += 15;
    if (title.trim().isNotEmpty) score += 15;
    if (city.trim().isNotEmpty) score += 15;
    if (phone.trim().isNotEmpty) score += 15;
    if (bio.trim().length >= 20) score += 20;
    if (skills.length >= 3) score += 20;

    return score;
  }

  bool _isProfileComplete({
    required String title,
    required String city,
    required String phone,
    required String bio,
    required List<String> skills,
  }) {
    return title.trim().isNotEmpty &&
        city.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        bio.trim().length >= 20 &&
        skills.length >= 3;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider);

    setState(() => _isSaving = true);

    try {
      final displayName = _displayNameController.text.trim();
      final title = _titleController.text.trim();
      final city = _cityController.text.trim();
      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();
      final skills = _parseSkills(_skillsController.text);

      final completionPercent = _calculateProfileCompletion(
        displayName: displayName,
        title: title,
        city: city,
        phone: phone,
        bio: bio,
        skills: skills,
      );

      final profileCompleted = _isProfileComplete(
        title: title,
        city: city,
        phone: phone,
        bio: bio,
        skills: skills,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'displayName': displayName,
        'title': title,
        'city': city,
        'phone': phone,
        'bio': bio,
        'skills': skills,
        'linkedinUrl': _linkedinController.text.trim(),
        'githubUrl': _githubController.text.trim(),
        'portfolioUrl': _portfolioController.text.trim(),
        'profileCompletionPercent': completionPercent,
        'profileCompleted': profileCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _helpText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.58),
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Identité professionnelle'),

                      TextFormField(
                        controller: _displayNameController,
                        decoration: _inputDecoration(
                          'Nom complet',
                          Icons.person_outline,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom complet est obligatoire.';
                          }
                          if (value.trim().length < 3) {
                            return 'Le nom est trop court.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration(
                          'Titre professionnel',
                          Icons.work_outline,
                        ),
                      ),
                      _helpText(
                        'Exemple : Ingénieur cybersécurité, Développeur Flutter, Administrateur réseau...',
                      ),

                      const SizedBox(height: 22),

                      TextFormField(
                        controller: _cityController,
                        decoration: _inputDecoration(
                          'Ville',
                          Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          'Téléphone',
                          Icons.phone_outlined,
                        ),
                      ),

                      const SizedBox(height: 30),
                      _sectionTitle('Présentation'),

                      TextFormField(
                        controller: _bioController,
                        maxLines: 5,
                        decoration: _inputDecoration(
                          'Résumé professionnel',
                          Icons.description_outlined,
                        ),
                      ),
                      _helpText(
                        'Décris brièvement ton profil, ton expérience, tes objectifs et tes points forts.',
                      ),

                      const SizedBox(height: 30),
                      _sectionTitle('Compétences'),

                      TextFormField(
                        controller: _skillsController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Compétences',
                          Icons.local_offer_outlined,
                        ),
                      ),
                      _helpText(
                        'Sépare les compétences par des virgules. Exemple : Fortinet, Cisco, Flutter, SOC, EDR/XDR',
                      ),

                      const SizedBox(height: 30),
                      _sectionTitle('Liens professionnels'),

                      TextFormField(
                        controller: _linkedinController,
                        keyboardType: TextInputType.url,
                        decoration: _inputDecoration(
                          'LinkedIn',
                          Icons.link_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _githubController,
                        keyboardType: TextInputType.url,
                        decoration: _inputDecoration(
                          'GitHub',
                          Icons.code_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _portfolioController,
                        keyboardType: TextInputType.url,
                        decoration: _inputDecoration(
                          'Portfolio / Site personnel',
                          Icons.language_outlined,
                        ),
                      ),

                      const SizedBox(height: 34),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: const Icon(Icons.save_outlined),
                          label: _isSaving
                              ? const CircularProgressIndicator()
                              : const Text('Enregistrer le profil'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  final int completionPercent;
  final bool hasCv;

  const _ProfileCompletionCard({
    required this.completionPercent,
    required this.hasCv,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedPercent = completionPercent.clamp(0, 100);
    final progressValue = normalizedPercent / 100;

    final isComplete = normalizedPercent >= 100 && hasCv;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isComplete
              ? Colors.greenAccent.withOpacity(0.45)
              : Colors.blueAccent.withOpacity(0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isComplete
                      ? Colors.greenAccent.withOpacity(0.14)
                      : Colors.blueAccent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isComplete
                      ? Icons.verified_outlined
                      : Icons.trending_up_outlined,
                  color: isComplete ? Colors.greenAccent : Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Profil complété à $normalizedPercent%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                hasCv
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: hasCv ? Colors.greenAccent : Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasCv ? 'CV PDF chargé' : 'CV PDF manquant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasCv ? Colors.greenAccent : Colors.amber,
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
