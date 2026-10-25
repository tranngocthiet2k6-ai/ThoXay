package vn.thoxay.exception;

import org.springframework.http.HttpStatus;

public class AccountLockedException extends ApiException {
    public static final String CODE = "ACCOUNT_LOCKED";
    public static final String MESSAGE = "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.";

    public AccountLockedException() {
        super(HttpStatus.FORBIDDEN, MESSAGE);
    }
}
