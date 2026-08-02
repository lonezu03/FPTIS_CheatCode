package com.fittrack.common.security;

import com.fittrack.auth.service.AuthCookieService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpMethod;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Set;

@Component
public class CsrfHeaderFilter extends OncePerRequestFilter {

    private static final Set<String> SAFE_METHODS = Set.of(
            HttpMethod.GET.name(),
            HttpMethod.HEAD.name(),
            HttpMethod.OPTIONS.name()
    );

    private final AuthCookieService cookieService;

    public CsrfHeaderFilter(AuthCookieService cookieService) {
        this.cookieService = cookieService;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        boolean cookieAuthenticated = cookieService.readAccessToken(request) != null
                || cookieService.readRefreshToken(request) != null;
        boolean bearerAuthenticated = request.getHeader("Authorization") != null;
        if (!SAFE_METHODS.contains(request.getMethod())
                && cookieAuthenticated
                && !bearerAuthenticated
                && !"XMLHttpRequest".equals(request.getHeader("X-Requested-With"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF protection header is required");
            return;
        }
        filterChain.doFilter(request, response);
    }
}
