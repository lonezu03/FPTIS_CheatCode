package com.fittrack.auth.exception;

public class EmailVerificationRequiredException extends RuntimeException {

    public EmailVerificationRequiredException(String message) {
        super(message);
    }
}
