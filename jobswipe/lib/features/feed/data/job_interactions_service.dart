import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobInteractionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _docId(String jobId, String userId) => '${jobId}_$userId';

  Future<void> toggleLike(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Utilisateur non connecté.';

    final likeRef = _firestore
        .collection('job_likes')
        .doc(_docId(jobId, user.uid));
    final jobRef = _firestore.collection('jobs').doc(jobId);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
      await jobRef.update({
        'likesCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await likeRef.set({
        'jobId': jobId,
        'candidateId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await jobRef.update({
        'likesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> toggleFavorite(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Utilisateur non connecté.';

    final favoriteRef = _firestore
        .collection('job_favorites')
        .doc(_docId(jobId, user.uid));
    final jobRef = _firestore.collection('jobs').doc(jobId);

    final favoriteDoc = await favoriteRef.get();

    if (favoriteDoc.exists) {
      await favoriteRef.delete();
      await jobRef.update({
        'favoritesCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await favoriteRef.set({
        'jobId': jobId,
        'candidateId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await jobRef.update({
        'favoritesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> registerView(String jobId) async {
    final user = _auth.currentUser;

    if (user == null) return;

    final viewId = '${jobId}_${user.uid}';

    final viewRef = _firestore.collection('job_views').doc(viewId);

    final existing = await viewRef.get();

    if (existing.exists) {
      return;
    }

    await viewRef.set({
      'jobId': jobId,
      'candidateId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('jobs').doc(jobId).update({
      'viewsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
