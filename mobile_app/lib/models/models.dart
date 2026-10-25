class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.expiresAt,
  });
  final String token, fullName, phoneNumber, role;
  final int userId;
  final DateTime expiresAt;
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String,
    userId: (json['userId'] as num).toInt(),
    fullName: json['fullName'] as String,
    phoneNumber: json['phoneNumber'] as String,
    role: json['role'] as String,
    expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'] as String)
        : DateTime.now().add(
            Duration(seconds: (json['expiresIn'] as num).toInt()),
          ),
  );
  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'role': role,
    'expiresAt': expiresAt.toIso8601String(),
  };
}

class Job {
  const Job({
    required this.id,
    required this.contractorId,
    required this.contractorName,
    required this.contractorPhone,
    required this.title,
    required this.description,
    required this.jobType,
    required this.salaryPerDay,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.requiredWorkers,
    required this.status,
    this.distanceKm,
  });
  final int id, contractorId, requiredWorkers;
  final String? contractorPhone;
  final String contractorName, title, description, jobType, address, status;
  final double salaryPerDay, latitude, longitude;
  final double? distanceKm;
  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: (json['id'] as num).toInt(),
    contractorId: (json['contractorId'] as num).toInt(),
    contractorName: json['contractorName'] as String,
    contractorPhone: json['contractorPhone'] as String?,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    jobType: json['jobType'] as String,
    salaryPerDay: (json['salaryPerDay'] as num).toDouble(),
    address: json['address'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    requiredWorkers: (json['requiredWorkers'] as num).toInt(),
    status: json['status'] as String,
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
  );
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.job,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.workerRating,
    required this.workerVerified,
    required this.workerActive,
    required this.status,
    this.jobRating,
  });
  final int id, workerId;
  final Job job;
  final String workerName, status;
  final String? workerPhone;
  final int? jobRating;
  final double workerRating;
  final bool workerVerified, workerActive;
  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
    id: (json['id'] as num).toInt(),
    job: Job.fromJson(json['job'] as Map<String, dynamic>),
    workerId: (json['workerId'] as num).toInt(),
    workerName: json['workerName'] as String,
    workerPhone: json['workerPhone'] as String?,
    workerRating: (json['workerRating'] as num).toDouble(),
    workerVerified: json['workerVerified'] as bool,
    workerActive: json['workerActive'] as bool,
    status: json['status'] as String,
    jobRating: (json['jobRating'] as num?)?.toInt(),
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.verified,
    required this.rating,
    this.cccdImage,
  });
  final int id;
  final String fullName, phoneNumber, role;
  final bool verified;
  final double rating;
  final String? cccdImage;
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: (json['id'] as num).toInt(),
    fullName: json['fullName'] as String,
    phoneNumber: json['phoneNumber'] as String,
    role: json['role'] as String,
    verified: json['verified'] as bool,
    rating: (json['rating'] as num).toDouble(),
    cccdImage: json['cccdImage'] as String?,
  );
}

String statusLabel(String status) => switch (status) {
  'OPEN' => 'Đang tuyển',
  'IN_PROGRESS' => 'Đang thi công',
  'COMPLETED' => 'Hoàn thành',
  'CANCELLED' => 'Đã hủy',
  'PENDING' => 'Chờ duyệt',
  'ACCEPTED' => 'Đã nhận',
  'REJECTED' => 'Từ chối',
  _ => status,
};

String money(double amount) =>
    '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
