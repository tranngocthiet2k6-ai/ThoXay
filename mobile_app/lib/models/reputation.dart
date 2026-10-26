class WorkerRank {
  WorkerRank.fromJson(Map<String, dynamic> j)
    : rank = (j['rank'] as num).toInt(),
      workerId = (j['workerId'] as num).toInt(),
      fullName = j['fullName'] as String,
      workerTier = j['workerTier'] as String,
      reputationScore = (j['reputationScore'] as num).toInt(),
      rating = (j['rating'] as num).toDouble(),
      completedJobs = (j['completedJobs'] as num).toInt(),
      verified = j['verified'] as bool;
  final int rank, workerId, reputationScore, completedJobs;
  final String fullName, workerTier;
  final double rating;
  final bool verified;
}

class WorkerReview {
  WorkerReview.fromJson(Map<String, dynamic> j)
    : id = (j['id'] as num).toInt(),
      stars = (j['stars'] as num).toInt(),
      jobTitle = j['jobTitle'] as String,
      contractorName = j['contractorName'] as String,
      reviewedAt = j['reviewedAt'] == null
          ? null
          : DateTime.parse(j['reviewedAt'] as String);
  final int id, stars;
  final String jobTitle, contractorName;
  final DateTime? reviewedAt;
}

class ReviewPage {
  const ReviewPage(this.items, this.hasMore);
  final List<WorkerReview> items;
  final bool hasMore;
}

class ReputationEntry {
  ReputationEntry.fromJson(Map<String, dynamic> j)
    : id = (j['id'] as num).toInt(),
      delta = (j['delta'] as num).toInt(),
      scoreAfter = (j['scoreAfter'] as num).toInt(),
      type = j['type'] as String,
      jobTitle = j['jobTitle'] as String,
      createdAt = DateTime.parse(j['createdAt'] as String);
  final int id, delta, scoreAfter;
  final String type, jobTitle;
  final DateTime createdAt;
}

class ReputationPage {
  const ReputationPage(this.items, this.hasMore);
  final List<ReputationEntry> items;
  final bool hasMore;
}
