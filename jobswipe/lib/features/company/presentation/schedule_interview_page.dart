import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScheduleInterviewPage extends StatefulWidget {
  final Map<String, dynamic> candidateData;

  const ScheduleInterviewPage({super.key, required this.candidateData});

  @override
  State<ScheduleInterviewPage> createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationOrLinkController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedMode = 'Téléphone';
  bool _isSaving = false;

  final List<String> _modes = const ['Téléphone', 'Présentiel', 'Visio'];

  bool get _isReschedule => widget.candidateData['isReschedule'] == true;

  @override
  void initState() {
    super.initState();

    final scheduledAt = widget.candidateData['scheduledAt'];
    if (scheduledAt is Timestamp) {
      final date = scheduledAt.toDate();
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedTime = TimeOfDay(hour: date.hour, minute: date.minute);
    }

    final mode = widget.candidateData['mode']?.toString() ?? '';
    if (mode.trim().isNotEmpty && _modes.contains(mode)) {
      _selectedMode = mode;
    }

    _locationOrLinkController.text =
        widget.candidateData['locationOrLink']?.toString() ?? '';
    _noteController.text = widget.candidateData['note']?.toString() ?? '';
  }

  @override
  void dispose() {
    _locationOrLinkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked == null) return;

    setState(() => _selectedTime = picked);
  }

  DateTime? _scheduledAt() {
    final date = _selectedDate;
    final time = _selectedTime;

    if (date == null || time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Heure';

    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createNotification({
    required String candidateId,
    required String companyName,
    required String jobTitle,
    required DateTime scheduledAt,
    required String mode,
    required bool isReschedule,
  }) async {
    final date =
        '${scheduledAt.day.toString().padLeft(2, '0')}/${scheduledAt.month.toString().padLeft(2, '0')}/${scheduledAt.year}';
    final time =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': candidateId,
      'title': isReschedule ? 'Entretien reporté' : 'Entretien planifié',
      'message': isReschedule
          ? '$companyName a reporté votre entretien pour "$jobTitle" au $date à $time. Mode : $mode.'
          : '$companyName a planifié un entretien pour "$jobTitle" le $date à $time. Mode : $mode.',
      'type': 'application_status',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _saveInterview() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduledAt = _scheduledAt();

    if (scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une date et une heure.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final interviewId = widget.candidateData['interviewId']?.toString() ?? '';
      final applicationId =
          widget.candidateData['applicationId']?.toString() ?? '';
      final candidateId = widget.candidateData['candidateId']?.toString() ?? '';
      final companyId = widget.candidateData['companyId']?.toString() ?? '';
      final jobId = widget.candidateData['jobId']?.toString() ?? '';
      final jobTitle = widget.candidateData['jobTitle']?.toString() ?? '';
      final companyName =
          widget.candidateData['companyName']?.toString() ?? 'Entreprise';
      final candidateName =
          widget.candidateData['fullName']?.toString() ?? 'Candidat';

      final interviewData = {
        'applicationId': applicationId,
        'candidateId': candidateId,
        'candidateName': candidateName,
        'companyId': companyId,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'mode': _selectedMode,
        'locationOrLink': _locationOrLinkController.text.trim(),
        'note': _noteController.text.trim(),
        'status': 'planned',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isReschedule && interviewId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('interviews')
            .doc(interviewId)
            .update(interviewData);
      } else {
        await FirebaseFirestore.instance.collection('interviews').add({
          ...interviewData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (applicationId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('applications')
            .doc(applicationId)
            .update({
              'status': 'interview',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      await _createNotification(
        candidateId: candidateId,
        companyName: companyName,
        jobTitle: jobTitle,
        scheduledAt: scheduledAt,
        mode: _selectedMode,
        isReschedule: _isReschedule,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isReschedule
                ? 'Entretien reporté avec succès.'
                : 'Entretien planifié avec succès.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’enregistrement : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidateName =
        widget.candidateData['fullName']?.toString() ?? 'Candidat';
    final jobTitle = widget.candidateData['jobTitle']?.toString() ?? '';
    final companyName =
        widget.candidateData['companyName']?.toString() ?? 'Entreprise';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReschedule ? 'Reporter entretien' : 'Planifier entretien',
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveInterview,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_available),
            label: Text(
              _isSaving
                  ? 'Enregistrement...'
                  : _isReschedule
                  ? 'Reporter l’entretien'
                  : 'Planifier l’entretien',
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _HeaderCard(
                  candidateName: candidateName,
                  jobTitle: jobTitle,
                  companyName: companyName,
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Créneau',
                  icon: Icons.schedule,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PickerBox(
                          icon: Icons.calendar_month,
                          label: _formatDate(_selectedDate),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickerBox(
                          icon: Icons.access_time,
                          label: _formatTime(_selectedTime),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Mode',
                  icon: Icons.meeting_room_outlined,
                  child: Row(
                    children: _modes.map((mode) {
                      final isSelected = mode == _selectedMode;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: mode == _modes.last ? 0 : 8,
                          ),
                          child: _ModeChip(
                            label: mode,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              _selectedMode = mode;
                            }),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _selectedMode == 'Présentiel'
                      ? 'Lieu'
                      : _selectedMode == 'Visio'
                      ? 'Lien visio'
                      : 'Contact',
                  icon: _selectedMode == 'Présentiel'
                      ? Icons.location_on_outlined
                      : _selectedMode == 'Visio'
                      ? Icons.video_call_outlined
                      : Icons.phone_outlined,
                  child: TextFormField(
                    controller: _locationOrLinkController,
                    decoration: InputDecoration(
                      hintText: _selectedMode == 'Présentiel'
                          ? 'Ex. Rabat, siège social'
                          : _selectedMode == 'Visio'
                          ? 'Ex. lien Google Meet / Teams'
                          : 'Ex. numéro ou instruction d’appel',
                      filled: true,
                      fillColor: const Color(0xFF0F1626),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (_selectedMode != 'Téléphone' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Ce champ est obligatoire.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Instructions',
                  icon: Icons.notes_outlined,
                  child: TextFormField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Note interne ou instructions pour le candidat',
                      filled: true,
                      fillColor: const Color(0xFF0F1626),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
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

class _HeaderCard extends StatelessWidget {
  final String candidateName;
  final String jobTitle;
  final String companyName;

  const _HeaderCard({
    required this.candidateName,
    required this.jobTitle,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = candidateName.trim().isNotEmpty
        ? candidateName.trim()[0].toUpperCase()
        : '?';

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
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blueAccent,
            child: Text(
              firstLetter,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.68)),
                ),
                const SizedBox(height: 2),
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 12,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
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
          child,
        ],
      ),
    );
  }
}

class _PickerBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1626),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF0F1626),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}
