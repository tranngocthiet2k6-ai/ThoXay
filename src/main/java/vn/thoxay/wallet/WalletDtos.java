package vn.thoxay.wallet;
import jakarta.validation.constraints.*;
import java.time.*;
import java.util.List;

public final class WalletDtos {
    private WalletDtos() { }
    public record CreateRequest(@NotBlank @Pattern(regexp="TOP_UP|WITHDRAW") String kind,
        @NotNull @Min(1000) @Max(100000000) Long amount,
        @NotBlank @Pattern(regexp="[A-Za-z0-9_-]{8,80}") String clientRequestId,
        @Size(max=200) String transferReference,@Size(max=100) String bankName,
        @Size(max=34) String bankAccount,@Size(max=100) String accountName) { }
    public record Transfer(@NotBlank @Pattern(regexp="LOCK|RELEASE") String direction,
        @NotNull @Min(1000) @Max(100000000) Long amount,@NotBlank @Pattern(regexp="[A-Za-z0-9_-]{8,80}") String clientRequestId) { }
    public record Review(@NotBlank @Pattern(regexp="APPROVE|REJECT") String decision,
        @Size(max=100) String externalReference,@Size(max=300) String note,Boolean confirmed) { }
    public record Pay(@NotNull @Positive Long applicationId,@NotNull @Min(1) @Max(366) Integer workDays,
        @NotNull @Min(0) @Max(100000000) Long tip,@NotNull @Min(0) @Max(100000000) Long bonus) { }
    public record Balance(long mainBalance,long escrowBalance,long heldBalance,long minimumEscrow,boolean lowEscrow,String currency) { }
    public record Request(Long id,Long userId,String fullName,String kind,String status,long amount,
        String transferReference,String bankName,String bankAccount,String accountName,String externalReference,
        String note,Instant createdAt,Instant processedAt,String depositReference) {
        public static Request of(WalletRequest r) {return new Request(r.getId(),r.getUser().getId(),r.getUser().getFullName(),r.getKind().name(),r.getStatus().name(),r.getAmount(),r.getTransferReference(),r.getBankName(),r.getBankAccount(),r.getAccountName(),r.getExternalReference(),r.getNote(),r.getCreatedAt(),r.getProcessedAt(),r.getDepositReference());}
    }
    public record Entry(Long id,String kind,long amount,long mainDelta,long escrowDelta,long heldDelta,
        long mainAfter,long escrowAfter,long heldAfter,String description,Instant createdAt) {
        public static Entry of(WalletEntry e) {return new Entry(e.getId(),e.getKind(),e.getAmount(),e.getMainDelta(),e.getEscrowDelta(),e.getHeldDelta(),e.getMainAfter(),e.getEscrowAfter(),e.getHeldAfter(),e.getDescription(),e.getCreatedAt());}
    }
    public record Page<T>(List<T> items,boolean hasMore) { }
    public record Earnings(String period,LocalDate from,LocalDate toExclusive,String timeZone,long base,long tip,long bonus,long total,long settledJobs) { }
    public record Payment(Long id,Long applicationId,Long workerId,String workerName,int workDays,long dailyRate,long base,long tip,long bonus,long total,Instant createdAt) {
        public static Payment of(JobPayment p) {return new Payment(p.getId(),p.getApplication()==null?null:p.getApplication().getId(),p.getWorker().getId(),p.getWorker().getFullName(),p.getWorkDays(),p.getDailyRate(),p.getBase(),p.getTip(),p.getBonus(),p.getTotal(),p.getCreatedAt());}
    }
}
