package com.fittrack.common.security;

import com.fittrack.user.entity.User;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component
public class FeatureAccessFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
                || !(authentication.getPrincipal() instanceof User user)
                || "ADMIN".equalsIgnoreCase(user.getRole())) {
            filterChain.doFilter(request, response);
            return;
        }

        String path = request.getRequestURI();
        String deniedModule = deniedModule(user, path);
        if (deniedModule == null) {
            filterChain.doFilter(request, response);
            return;
        }

        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType("application/json");
        response.getWriter().write(
                "{\"status\":403,\"error\":\"Forbidden\",\"message\":\""
                        + "Tài khoản chưa được cấp quyền sử dụng "
                        + deniedModule
                        + "\"}"
        );
    }

    private String deniedModule(User user, String path) {
        if (path.startsWith("/api/lunch")
                && !Boolean.TRUE.equals(user.getLunchEnabled())) {
            return "Đặt cơm";
        }
        if (path.startsWith("/api/assistant")
                && !Boolean.TRUE.equals(user.getChatbotEnabled())) {
            return "Chatbot";
        }
        if (isFitnessPath(path)
                && !Boolean.TRUE.equals(user.getFitnessEnabled())) {
            return "Fitness";
        }
        if (isHealthPath(path)
                && !Boolean.TRUE.equals(user.getHealthEnabled())) {
            return "Chăm sóc sức khỏe";
        }
        return null;
    }

    private boolean isFitnessPath(String path) {
        return path.startsWith("/api/workouts")
                || path.startsWith("/api/workout-plans")
                || path.startsWith("/api/exercises")
                || path.startsWith("/api/achievements");
    }

    private boolean isHealthPath(String path) {
        return path.startsWith("/api/foods")
                || path.startsWith("/api/nutrition")
                || path.startsWith("/api/body-measurements")
                || path.startsWith("/api/reports")
                || path.startsWith("/api/recommendations")
                || path.startsWith("/api/health-management")
                || path.startsWith("/api/reminders");
    }
}
