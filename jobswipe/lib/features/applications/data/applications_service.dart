import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class ApplicationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _hasMinimumCandidateProfile(Map<String, dynamic> data) {
    final title = data['title']?.toString().trim() ?? '';
    final city = data['city']?.toString().trim() ?? '';
    final phone = data['phone']?.toString().trim() ?? '';
    final bio = data['bio']?.toString().trim() ?? '';
    final cvUrl = data['cvUrl']?.toString().trim() ?? '';

    final skillsRaw = data['skills'];
    final skillsCount = skillsRaw is List
        ? skillsRaw.where((skill) => skill.toString().trim().isNotEmpty).length
        : 0;

    return title.isNotEmpty &&
        city.isNotEmpty &&
        phone.isNotEmpty &&
        bio.length >= 20 &&
        skillsCount >= 3 &&
        cvUrl.isNotEmpty;
  }

  List<String> _missingCandidateProfileFields(Map<String, dynamic> data) {
    final missing = <String>[];

    final title = data['title']?.toString().trim() ?? '';
    final city = data['city']?.toString().trim() ?? '';
    final phone = data['phone']?.toString().trim() ?? '';
    final bio = data['bio']?.toString().trim() ?? '';
    final cvUrl = data['cvUrl']?.toString().trim() ?? '';

    final skillsRaw = data['skills'];
    final skillsCount = skillsRaw is List
        ? skillsRaw.where((skill) => skill.toString().trim().isNotEmpty).length
        : 0;

    if (title.isEmpty) missing.add('titre professionnel');
    if (city.isEmpty) missing.add('ville');
    if (phone.isEmpty) missing.add('téléphone');
    if (bio.length < 20) missing.add('résumé professionnel');
    if (skillsCount < 3) missing.add('au moins 3 compétences');
    if (cvUrl.isEmpty) missing.add('CV PDF');

    return missing;
  }

  Future<void> applyToJob(JobOffer job) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw 'Utilisateur non connecté.';
    }

    final existingApplication = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: job.id)
        .where('candidateId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existingApplication.docs.isNotEmpty) {
      throw 'Vous avez déjà postulé à cette offre.';
    }

    final candidateDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final candidateData = candidateDoc.data() ?? {};

    if (!_hasMinimumCandidateProfile(candidateData)) {
      final missingFields = _missingCandidateProfileFields(candidateData);

      throw 'Profil incomplet. Complétez votre ${missingFields.join(', ')} avant de postuler.';
    }

    final candidateName =
        candidateData['displayName']?.toString() ??
        user.displayName ??
        user.email ??
        'Candidat';

    final candidateEmail =
        candidateData['email']?.toString() ?? user.email ?? '';

    final candidateCvUrl = candidateData['cvUrl']?.toString() ?? '';
    final candidateCvFileName = candidateData['cvFileName']?.toString() ?? '';
    final candidateVideoCvUrl = candidateData['videoCvUrl']?.toString() ?? '';
    final candidateVideoCvFileName =
        candidateData['videoCvFileName']?.toString() ?? '';
    final candidateVideoCvThumbnailUrl =
        candidateData['videoCvThumbnailUrl']?.toString() ?? '';
    final applicationId = '${job.id}_${user.uid}';
    await _firestore.collection('applications').doc(applicationId).set({
      'jobId': job.id,
      'candidateId': user.uid,
      'candidateName': candidateName,
      'candidateEmail': candidateEmail,
      'candidateCvUrl': candidateCvUrl,
      'candidateCvFileName': candidateCvFileName,
      'candidateVideoCvUrl': candidateVideoCvUrl,
      'candidateVideoCvFileName': candidateVideoCvFileName,
      'candidateVideoCvThumbnailUrl': candidateVideoCvThumbnailUrl,
      'candidatePhone': candidateData['phone']?.toString() ?? '',
      'candidateCity': candidateData['city']?.toString() ?? '',
      'candidateBio': candidateData['bio']?.toString() ?? '',
      'candidateSkills': candidateData['skills'] is List
          ? (candidateData['skills'] as List).join(', ')
          : candidateData['skills']?.toString() ?? '',
      'companyId': job.companyId,
      'companyName': job.companyName,
      'jobTitle': job.title,
      'status': 'submitted',
      'submittedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('jobs').doc(job.id).update({
      'applicationsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
