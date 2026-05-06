import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class ApplicationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    await _firestore.collection('applications').add({
      'jobId': job.id,
      'candidateId': user.uid,
      'companyId': job.companyId,
      'companyName': job.companyName,
      'jobTitle': job.title,
      'status': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('jobs').doc(job.id).update({
      'applicationsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
