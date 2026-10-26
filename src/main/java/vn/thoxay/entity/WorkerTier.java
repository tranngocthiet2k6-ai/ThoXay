package vn.thoxay.entity;

public enum WorkerTier {
    SILVER, GOLD, DIAMOND;
    public static WorkerTier of(User worker) {
        if (worker.getRole() != Role.ROLE_WORKER) return SILVER;
        if (worker.getReputationScore() >= 95 && worker.getRating() >= 4.7 && worker.getCompletedJobs() >= 20 && worker.isVerified()) return DIAMOND;
        if (worker.getReputationScore() >= 80 && worker.getRating() >= 4.0 && worker.getCompletedJobs() >= 5) return GOLD;
        return SILVER;
    }
}
