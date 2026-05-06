import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/shared/models/application_model.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

final companyJobsProvider = StreamProvider.family<List<JobOffer>, String>((
  ref,
  companyId,
) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('companyId', isEqualTo: companyId)
      .snapshots()
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

final companyApplicationsProvider =
    StreamProvider.family<List<ApplicationModel>, String>((ref, companyId) {
      return FirebaseFirestore.instance
          .collection('applications')
          .where('companyId', isEqualTo: companyId)
          .snapshots()
          .map((snapshot) {
            final applications = snapshot.docs
                .map(ApplicationModel.fromFirestore)
                .toList();

            applications.sort((a, b) {
              final aDate = a.createdAt;
              final bDate = b.createdAt;

              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;

              return bDate.compareTo(aDate);
            });

            return applications;
          });
    });
