package vn.thoxay.exception;

import jakarta.validation.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import java.util.Map;
import java.util.stream.Collectors;

@RestControllerAdvice(annotations = RestController.class)
public class ApiExceptionHandler {
    @ExceptionHandler(org.springframework.web.multipart.MaxUploadSizeExceededException.class)
    ResponseEntity<?> tooLarge(Exception e) { return error(HttpStatus.PAYLOAD_TOO_LARGE, "Mỗi ảnh tối đa 5 MB, tổng yêu cầu tối đa 11 MB"); }
    @ExceptionHandler(org.springframework.web.multipart.support.MissingServletRequestPartException.class)
    ResponseEntity<?> missingPhoto(Exception e) { return error(HttpStatus.BAD_REQUEST, "Cần đủ ảnh mặt trước và mặt sau CCCD"); }
    @ExceptionHandler(AccountLockedException.class)
    ResponseEntity<?> locked(AccountLockedException e) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("status", 403,
            "code", AccountLockedException.CODE, "message", e.getMessage()));
    }
    @ExceptionHandler(ApiException.class)
    ResponseEntity<?> business(ApiException e) { return error(e.getStatus(), e.getMessage()); }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<?> validation(MethodArgumentNotValidException e) {
        return error(HttpStatus.BAD_REQUEST, e.getBindingResult().getFieldErrors().stream()
            .map(f -> f.getField() + ": " + f.getDefaultMessage()).collect(Collectors.joining("; ")));
    }

    @ExceptionHandler({ConstraintViolationException.class, HandlerMethodValidationException.class,
        HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    ResponseEntity<?> invalid(Exception e) { return error(HttpStatus.BAD_REQUEST, "Dữ liệu yêu cầu không hợp lệ"); }

    @ExceptionHandler(AuthenticationException.class)
    ResponseEntity<?> authentication(AuthenticationException e) {
        return error(HttpStatus.UNAUTHORIZED, "Sai số điện thoại hoặc mật khẩu");
    }

    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<?> forbidden(AccessDeniedException e) { return error(HttpStatus.FORBIDDEN, "Bạn không có quyền thực hiện thao tác này"); }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<?> conflict(DataIntegrityViolationException e) { return error(HttpStatus.CONFLICT, "Dữ liệu trùng lặp hoặc không hợp lệ"); }

    private ResponseEntity<?> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("status", status.value(), "message", message));
    }
}
