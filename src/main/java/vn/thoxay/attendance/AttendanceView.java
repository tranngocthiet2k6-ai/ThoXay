package vn.thoxay.attendance;
import java.time.*;
public record AttendanceView(Long id,Long applicationId,Long workerId,String workerName,LocalDate workDay,
 Instant checkedInAt,Instant checkedOutAt,String checkinMethod,String checkoutMethod,
 Long logId,String caption,String reviewStatus,String feedback,Long logVersion,boolean hasDetailPhoto,
 Long version,Long correctionId,String correctionStatus,String correctionReason,String correctionFeedback,
 boolean canUndoCheckout){}
