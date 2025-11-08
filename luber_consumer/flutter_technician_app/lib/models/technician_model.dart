class TechnicianModel {
  final String id;
  final String userId;
  final String certificationNumber;
  final int yearsExperience;
  final String? bio;
  final String? certificationPhotoUrl;
  final String? profilePhotoUrl;
  final String status;
  final double? rating;
  final int totalJobs;
  final bool isAvailable;
  final DateTime createdAt;

  TechnicianModel({
    required this.id,
    required this.userId,
    required this.certificationNumber,
    required this.yearsExperience,
    this.bio,
    this.certificationPhotoUrl,
    this.profilePhotoUrl,
    required this.status,
    this.rating,
    required this.totalJobs,
    required this.isAvailable,
    required this.createdAt,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['id'],
      userId: json['user_id'],
      certificationNumber: json['certification_number'],
      yearsExperience: json['years_experience'],
      bio: json['bio'],
      certificationPhotoUrl: json['certification_photo_url'],
      profilePhotoUrl: json['profile_photo_url'],
      status: json['status'],
      rating: json['rating']?.toDouble(),
      totalJobs: json['total_jobs'] ?? 0,
      isAvailable: json['is_available'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}
