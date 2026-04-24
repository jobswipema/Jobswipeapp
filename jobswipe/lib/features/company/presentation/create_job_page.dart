import 'package:flutter/material.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();

  String _contractType = 'CDI';
  String _experienceLevel = 'Débutant';
  String _category = 'Développement';
  bool _videoSelected = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _selectMockVideo() {
    setState(() {
      _videoSelected = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vidéo sélectionnée en mode simulation')),
    );
  }

  void _publishJob() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_videoSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une vidéo pour l’offre.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offre créée avec succès en mode simulation.'),
      ),
    );
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              letterSpacing: 0.3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label, icon).copyWith(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
      dropdownColor: const Color(0xFF1A2235),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleController.text.trim().isEmpty
        ? 'Titre de l’offre'
        : _titleController.text.trim();

    final location = _locationController.text.trim().isEmpty
        ? 'Ville'
        : _locationController.text.trim();

    final salary = _salaryController.text.trim().isEmpty
        ? 'Salaire optionnel'
        : _salaryController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une offre')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Informations de l’offre'),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        'Titre du poste',
                        Icons.work_outline,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le titre du poste est obligatoire.';
                        }
                        if (value.trim().length < 3) {
                          return 'Le titre est trop court.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Description de l’offre',
                        Icons.description_outlined,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La description est obligatoire.';
                        }
                        if (value.trim().length < 20) {
                          return 'La description doit contenir au moins 20 caractères.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration(
                        'Localisation',
                        Icons.location_on_outlined,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La localisation est obligatoire.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _dropdown(
                      label: 'Type de contrat',
                      value: _contractType,
                      icon: Icons.badge_outlined,
                      items: const [
                        'CDI',
                        'CDD',
                        'Stage',
                        'Freelance',
                        'Alternance',
                      ],

                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _contractType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    _dropdown(
                      label: 'Niveau d’expérience',
                      value: _experienceLevel,
                      icon: Icons.timeline_outlined,
                      items: const [
                        'Débutant',
                        '1 an exp.',
                        '2 ans exp.',
                        '3 ans exp.',
                        '5 ans et plus',
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _experienceLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    _dropdown(
                      label: 'Catégorie métier',
                      value: _category,
                      icon: Icons.category_outlined,
                      items: const [
                        'Développement',
                        'Réseau',
                        'Cybersécurité',
                        'Data',
                        'Cloud',
                        'Support IT',
                        'Commercial IT',
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _category = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _salaryController,
                      decoration: _inputDecoration(
                        'Salaire affiché',
                        Icons.payments_outlined,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              _sectionTitle('Vidéo de l’offre'),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1A2235), const Color(0xFF131A2B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _videoSelected ? Colors.greenAccent : Colors.white12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _videoSelected
                          ? Icons.check_circle_outline
                          : Icons.video_library_outlined,
                      size: 42,
                      color: _videoSelected
                          ? Colors.greenAccent
                          : Colors.white70,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _videoSelected
                          ? 'Vidéo sélectionnée'
                          : 'Aucune vidéo sélectionnée',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pour cette étape, la sélection vidéo est simulée. L’upload réel Firebase Storage sera ajouté plus tard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _selectMockVideo,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Sélectionner une vidéo'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              _sectionTitle('Aperçu de l’offre'),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Votre entreprise • $location',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _previewChip(_contractType),
                        _previewChip(_experienceLevel),
                        _previewChip(salary),
                        _previewChip(_category),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _descriptionController.text.trim().isEmpty
                          ? 'Description courte de l’offre affichée ici.'
                          : _descriptionController.text.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _publishJob,
                  icon: const Icon(Icons.publish_outlined),
                  label: const Text('Publier l’offre'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.55)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
