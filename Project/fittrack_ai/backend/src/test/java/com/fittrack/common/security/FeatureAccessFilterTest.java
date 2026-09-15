package com.fittrack.common.security;

import com.fittrack.user.entity.User;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class FeatureAccessFilterTest {

    private final FeatureAccessFilter filter = new FeatureAccessFilter();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void quoteEndpointsAreDeniedWithoutQuotePermission() throws Exception {
        authenticate(user("USER", false));

        assertDenied("/api/quotes/today");
        assertDenied("/api/quote-tags");
    }

    @Test
    void quoteEndpointsAreAllowedWithQuotePermission() throws Exception {
        authenticate(user("USER", true));
        AtomicBoolean continued = new AtomicBoolean(false);

        filter.doFilter(
                new MockHttpServletRequest("GET", "/api/quotes/today"),
                new MockHttpServletResponse(),
                (request, response) -> continued.set(true)
        );

        assertTrue(continued.get());
    }

    @Test
    void adminBypassesQuotePermission() throws Exception {
        authenticate(user("ADMIN", false));
        AtomicBoolean continued = new AtomicBoolean(false);

        filter.doFilter(
                new MockHttpServletRequest("GET", "/api/quotes/today"),
                new MockHttpServletResponse(),
                (request, response) -> continued.set(true)
        );

        assertTrue(continued.get());
    }

    @Test
    void financeEndpointsRequireIndependentPermission() throws Exception {
        User denied = user("USER", false);
        denied.setFinanceEnabled(false);
        authenticate(denied);
        MockHttpServletResponse deniedResponse = new MockHttpServletResponse();
        filter.doFilter(
                new MockHttpServletRequest("GET", "/api/finance/dashboard"),
                deniedResponse,
                (request, response) -> { throw new AssertionError("Must not continue"); }
        );
        assertEquals(403, deniedResponse.getStatus());

        User allowed = user("USER", false);
        allowed.setFinanceEnabled(true);
        authenticate(allowed);
        AtomicBoolean continued = new AtomicBoolean(false);
        filter.doFilter(
                new MockHttpServletRequest("GET", "/api/finance/dashboard"),
                new MockHttpServletResponse(),
                (request, response) -> continued.set(true)
        );
        assertTrue(continued.get());
    }

    private void assertDenied(String uri) throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        AtomicBoolean continued = new AtomicBoolean(false);

        filter.doFilter(
                new MockHttpServletRequest("GET", uri),
                response,
                (request, servletResponse) -> continued.set(true)
        );

        assertFalse(continued.get());
        assertEquals(403, response.getStatus());
        assertTrue(response.getContentAsString().contains("Câu nói yêu thích"));
    }

    private void authenticate(User user) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(user, null, List.of())
        );
    }

    private User user(String role, boolean quoteEnabled) {
        return User.builder()
                .id("user-1")
                .email("user@example.test")
                .password("encoded")
                .role(role)
                .active(true)
                .quoteEnabled(quoteEnabled)
                .build();
    }
}
