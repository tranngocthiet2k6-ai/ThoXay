class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.fullName,
    required this.verified,
    required this.rating,
    required this.experienceYears,
    required this.experienceSummary,
    required this.skills,
    required this.projectImages,
    this.reputationScore = 100,
    this.completedJobs = 0,
    this.workerTier = 'SILVER',
  });
  final int id, experienceYears;
  final String fullName, experienceSummary;
  final bool verified;
  final double rating;
  final List<String> skills, projectImages;
  final int reputationScore, completedJobs;
  final String workerTier;
  factory WorkerProfile.fromJson(Map<String, dynamic> json) => WorkerProfile(
    id: (json['id'] as num).toInt(),
    fullName: json['fullName'] as String,
    verified: json['verified'] as bool,
    rating: (json['rating'] as num).toDouble(),
    experienceYears: (json['experienceYears'] as num).toInt(),
    experienceSummary: json['experienceSummary'] as String? ?? '',
    skills: (json['skills'] as List).cast<String>(),
    projectImages: (json['projectImages'] as List).cast<String>(),
    reputationScore: (json['reputationScore'] as num?)?.toInt() ?? 100,
    completedJobs: (json['completedJobs'] as num?)?.toInt() ?? 0,
    workerTier: json['workerTier'] as String? ?? 'SILVER',
  );
}
