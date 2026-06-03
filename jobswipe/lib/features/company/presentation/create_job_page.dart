import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jobswipe/shared/services/cloudinary_service.dart';
import 'package:jobswipe/shared/services/cloudinary_service.dart';

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

  String _videoUrl = '';
  String _videoFileName = '';

  bool _isUploadingVideo = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectAndUploadVideo() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnack('Utilisateur non connecté.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'm4v'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.bytes == null) {
      _showSnack('Impossible de lire la vidéo sélectionnée.');
      return;
    }

    if (file.size > 50 * 1024 * 1024) {
      _showSnack('La vidéo ne doit pas dépasser 50 Mo.');
      return;
    }

    setState(() => _isUploadingVideo = true);

    try {
      final videoUrl = await CloudinaryService.uploadVideo(
        fileBytes: file.bytes!,
        fileName: file.name,
        folder: 'jobswipe/videos/${user.uid}',
      );

      setState(() {
        _videoUrl = videoUrl;
        _videoFileName = file.name;
      });

      _showSnack('Vidéo téléversée avec succès.');
    } catch (e) {
      _showSnack('Erreur upload vidéo : $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingVideo = false);
      }
    }
  }

  Future<void> _publishJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_videoUrl.isEmpty) {
      _showSnack('Veuillez téléverser une vidéo pour publier l’offre.');
      return;
    }
    final thumbnailUrl = CloudinaryService.generateVideoThumbnailUrl(_videoUrl);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnack('Utilisateur non connecté.');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final companyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final companyData = companyDoc.data() ?? {};
      final companyName =
          companyData['displayName']?.toString() ?? 'Entreprise';

      await FirebaseFirestore.instance.collection('jobs').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'companyId': user.uid,
        'companyName': companyName,
        'location': _locationController.text.trim(),
        'contractType': _contractType,
        'experienceLevel': _experienceLevel,
        'category': _category,
        'salary': _salaryController.text.trim().isNotEmpty
            ? int.tryParse(_salaryController.text.trim())
            : null,
        'videoUrl': _videoUrl,
        'videoFileName': _videoFileName,
        'thumbnailUrl': thumbnailUrl,
        'viewsCount': 0,
        'likesCount': 0,
        'favoritesCount': 0,
        'applicationsCount': 0,
        'isActive': true,
        'jobStatus': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSnack('Offre publiée avec succès.');
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Erreur publication offre : $e');
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        : '${_salaryController.text.trim()} MAD';

    final hasVideo = _videoUrl.isNotEmpty;

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
                        setState(() => _contractType = value);
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
                        setState(() => _experienceLevel = value);
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
                        setState(() => _category = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _salaryController,
                      keyboardType: TextInputType.number,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2235), Color(0xFF131A2B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: hasVideo ? Colors.greenAccent : Colors.white12,
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
                      hasVideo
                          ? Icons.check_circle_outline
                          : Icons.video_library_outlined,
                      size: 42,
                      color: hasVideo ? Colors.greenAccent : Colors.white70,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      hasVideo ? 'Vidéo téléversée' : 'Aucune vidéo téléversée',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasVideo
                          ? _videoFileName
                          : 'Sélectionnez une vidéo verticale MP4/MOV. Taille maximale recommandée : 50 Mo.',
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
                        onPressed: _isUploadingVideo
                            ? null
                            : _selectAndUploadVideo,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _isUploadingVideo
                              ? 'Téléversement...'
                              : hasVideo
                              ? 'Remplacer la vidéo'
                              : 'Téléverser une vidéo',
                        ),
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
                  onPressed: _isPublishing ? null : _publishJob,
                  icon: const Icon(Icons.publish_outlined),
                  label: Text(
                    _isPublishing ? 'Publication...' : 'Publier l’offre',
                  ),
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
