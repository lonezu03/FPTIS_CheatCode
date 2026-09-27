package com.fittrack.journal.service;

import com.fittrack.user.entity.User;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component @RequiredArgsConstructor
public class JournalLockFilter extends OncePerRequestFilter {
    private final JournalService service;
    @Override protected void doFilterInternal(@NonNull HttpServletRequest request,@NonNull HttpServletResponse response,@NonNull FilterChain chain)throws ServletException,IOException{
        String path=request.getRequestURI();
        if(!path.startsWith("/api/journal")||path.equals("/api/journal/lock/status")||path.equals("/api/journal/lock/unlock")){chain.doFilter(request,response);return;}
        var auth=SecurityContextHolder.getContext().getAuthentication();
        if(auth!=null&&auth.getPrincipal() instanceof User user&&!service.isUnlocked(user,request.getHeader("X-Journal-Unlock"))){response.setStatus(423);response.setCharacterEncoding(StandardCharsets.UTF_8.name());response.setContentType("application/json");response.getWriter().write("{\"status\":423,\"error\":\"Locked\",\"message\":\"Nhật ký đang được khóa\"}");return;}
        chain.doFilter(request,response);
    }
}
