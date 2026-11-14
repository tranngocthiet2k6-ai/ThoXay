package vn.thoxay.controller;

import org.springframework.web.bind.annotation.*;
import vn.thoxay.entity.WorkerTier;
import java.util.*;

@RestController @RequestMapping("/api/reputation/tiers")
public class TierController {
    public record Rule(String code, String name, int minReputation, int minCompletedJobs, double minRating,
        boolean requiresKyc, List<String> benefits) { }
    public record Guide(List<Rule> tiers, String priorityPolicy, String feePolicy) { }
    @GetMapping public Guide guide() {
        return new Guide(Arrays.stream(WorkerTier.values()).map(tier -> new Rule(tier.name(), switch (tier) {
            case BRONZE -> "Đồng · Khởi đầu"; case SILVER -> "Bạc"; case GOLD -> "Vàng"; case DIAMOND -> "Kim Cương";
        }, tier.minReputation, tier.minCompletedJobs, tier.minRating, tier.requiresKyc, switch (tier) {
            case BRONZE -> List.of("Sử dụng hồ sơ nghề nghiệp, tìm việc và ứng tuyển", "Tích lũy công trình và đánh giá thực tế để lên Bạc");
            case SILVER -> List.of("Huy hiệu Bạc trên hồ sơ", "Xếp trước bậc Đồng trong danh sách ứng viên của chủ thầu");
            case GOLD -> List.of("Huy hiệu Vàng ghi nhận kinh nghiệm", "Xếp trước bậc Đồng/Bạc trong danh sách ứng viên");
            case DIAMOND -> List.of("Huy hiệu Kim Cương với định danh KYC", "Thứ tự hiển thị cao nhất theo bậc trong danh sách ứng viên");
        })).toList(), "Ưu tiên sắp xếp ứng viên theo bậc, cùng bậc xếp theo thời điểm ứng tuyển mới nhất. Không tự động duyệt hoặc bảo đảm nhận việc.",
        "Hiện chưa thu phí nền tảng theo bậc. Ưu đãi giảm phí theo hạng chưa áp dụng; tiền công, tip và thưởng vẫn theo giao dịch đã chốt.");
    }
}
