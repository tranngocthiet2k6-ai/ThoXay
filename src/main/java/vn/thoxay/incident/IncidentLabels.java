package vn.thoxay.incident;
import org.springframework.stereotype.Component;
import java.time.*;
import java.time.format.DateTimeFormatter;
@Component("incidentLabels")
public class IncidentLabels {
 private static final DateTimeFormatter TIME=DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm").withZone(ZoneId.of("Asia/Ho_Chi_Minh"));
 public String status(String value){return switch(value){case "NEW"->"Mới gửi";case "IN_REVIEW"->"Đang xử lý";case "RESOLVED"->"Đã có kết quả";default->value;};}
 public String type(String value){return switch(value){case "SOS"->"SOS khẩn cấp";case "SAFETY"->"An toàn công trường";case "PAYMENT_DISPUTE"->"Tranh chấp thanh toán";default->"Sự cố khác";};}
 public String time(Instant value){return value==null?"":TIME.format(value);}
}
