import 'package:cloud_firestore/cloud_firestore.dart';

class JobOffer {
  final String id;
  final String companyId;
  final String companyName;
  final bool companyVerified;
  final String title;
  final String location;
  final String contractType;
  final String experience;
  final String salary;
  final String category;
  final String description;
  final bool isActive;
  final DateTime? createdAt;

  final String videoUrl;
  final String videoFileName;
  final String thumbnailUrl;

  final int viewsCount;
  final int likesCount;
  final int favoritesCount;
  final int applicationsCount;

  const JobOffer({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.companyVerified,
    required this.title,
    required this.location,
    required this.contractType,
    required this.experience,
    required this.salary,
    required this.category,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.videoUrl,
    required this.videoFileName,
    required this.thumbnailUrl,
    required this.viewsCount,
    required this.likesCount,
    required this.favoritesCount,
    required this.applicationsCount,
  });

  factory JobOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return JobOffer(
      id: doc.id,
      companyId: data['companyId']?.toString() ?? '',
      companyName: data['companyName']?.toString() ?? 'Entreprise',
      companyVerified: true,
      title: data['title']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      contractType: data['contractType']?.toString() ?? '',
      experience: data['experienceLevel']?.toString() ?? '',
      salary: data['salary'] != null
          ? '${data['salary']} MAD'
          : 'Salaire non précisé',
      category: data['category']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      isActive: data['isActive'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      videoUrl: data['videoUrl']?.toString() ?? '',
      videoFileName: data['videoFileName']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      viewsCount: _toInt(data['viewsCount']),
      likesCount: _toInt(data['likesCount']),
      favoritesCount: _toInt(data['favoritesCount']),
      applicationsCount: _toInt(data['applicationsCount']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
