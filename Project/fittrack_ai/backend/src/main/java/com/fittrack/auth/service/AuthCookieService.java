package com.fittrack.auth.service;

import com.fittrack.common.security.JwtService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Arrays;

@Service
public class AuthCookieService {

    public static final String ACCESS_COOKIE = "fittrack_access";
    public static final String REFRESH_COOKIE = "fittrack_refresh";

    private final JwtService jwtService;
    private final boolean secure;
    private final String sameSite;
    private final int refreshExpirationDays;

    public AuthCookieService(
            JwtService jwtService,
            @Value("${app.auth.cookie-secure:false}") boolean secure,
            @Value("${app.auth.cookie-same-site:Lax}") String sameSite,
            @Value("${app.jwt.refresh-expiration-days:30}") int refreshExpirationDays
    ) {
        this.jwtService = jwtService;
        this.secure = secure;
        this.sameSite = sameSite;
        this.refreshExpirationDays = refreshExpirationDays;
    }

    public void writeSession(
            HttpServletResponse response,
            AuthService.AuthSession session
    ) {
        add(response, ACCESS_COOKIE, session.response().getToken(),
                Duration.ofMillis(jwtService.getExpirationMs()));
        add(response, REFRESH_COOKIE, session.refreshToken(),
                Duration.ofDays(refreshExpirationDays));
    }

    public void clearSession(HttpServletResponse response) {
        add(response, ACCESS_COOKIE, "", Duration.ZERO);
        add(response, REFRESH_COOKIE, "", Duration.ZERO);
    }

    public String readAccessToken(HttpServletRequest request) {
        return readCookie(request, ACCESS_COOKIE);
    }

    public String readRefreshToken(HttpServletRequest request) {
        return readCookie(request, REFRESH_COOKIE);
    }

    private String readCookie(HttpServletRequest request, String name) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        return Arrays.stream(cookies)
                .filter(cookie -> name.equals(cookie.getName()))
                .map(Cookie::getValue)
                .findFirst()
                .orElse(null);
    }

    private void add(
            HttpServletResponse response,
            String name,
            String value,
            Duration maxAge
    ) {
        ResponseCookie cookie = ResponseCookie.from(name, value)
                .httpOnly(true)
                .secure(secure)
                .sameSite(sameSite)
                .path("/")
                .maxAge(maxAge)
                .build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
    }
}
