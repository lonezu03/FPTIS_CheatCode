package com.fittrack.common.security;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("prod")
public class ProductionSecurityValidator {

    private final String jwtSecret;

    public ProductionSecurityValidator(@Value("${app.jwt.secret}") String jwtSecret) {
        this.jwtSecret = jwtSecret;
    }

    @PostConstruct
    void validate() {
        if (jwtSecret == null
                || jwtSecret.length() < 48
                || jwtSecret.contains("fittrack_super_secret")
                || jwtSecret.contains("local-development-only")
                || jwtSecret.toLowerCase().contains("change_me")) {
            throw new IllegalStateException(
                    "JWT_SECRET production phải là chuỗi ngẫu nhiên tối thiểu 48 ký tự và không dùng giá trị mặc định"
            );
        }
    }
}
