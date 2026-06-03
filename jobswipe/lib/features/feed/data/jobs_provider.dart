import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

final jobsStreamProvider = StreamProvider.autoDispose<List<JobOffer>>((ref) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('isActive', isEqualTo: true)
      .where('jobStatus', isEqualTo: 'open')
      .snapshots(includeMetadataChanges: false)
      .map((snapshot) {
        final jobs = snapshot.docs.map(JobOffer.fromFirestore).toList();

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
});
