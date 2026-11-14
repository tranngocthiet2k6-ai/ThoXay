package vn.thoxay.entity;

public enum WorkerTier {
    BRONZE(0, 0, 0, false), SILVER(60, 1, 3.0, false), GOLD(80, 5, 4.0, false), DIAMOND(95, 20, 4.7, true);
    public final int minReputation, minCompletedJobs;
    public final double minRating;
    public final boolean requiresKyc;
    WorkerTier(int reputation, int jobs, double rating, boolean kyc) {
        minReputation = reputation; minCompletedJobs = jobs; minRating = rating; requiresKyc = kyc;
    }
    public static WorkerTier of(User worker) {
        if (worker.getRole() != Role.ROLE_WORKER) return BRONZE;
        var tiers = values();
        for (int index = tiers.length - 1; index >= 0; index--) {
            var tier = tiers[index];
            if (worker.getReputationScore() >= tier.minReputation && worker.getRating() >= tier.minRating
                && worker.getCompletedJobs() >= tier.minCompletedJobs && (!tier.requiresKyc || worker.isVerified())) return tier;
        }
        return BRONZE;
    }
}
