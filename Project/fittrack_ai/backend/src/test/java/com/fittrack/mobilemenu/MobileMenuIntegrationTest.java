package com.fittrack.mobilemenu;

import com.fittrack.FittrackBackendApplication;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.http.MediaType;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = FittrackBackendApplication.class) @ActiveProfiles("test") @Transactional
class MobileMenuIntegrationTest {
    @Autowired MobileMenuService service;
    @Autowired MobileMenuRepository repository;
    @Autowired ObjectMapper json;
    @Autowired WebApplicationContext context;
    MockMvc mvc;
    @BeforeEach void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        repository.deleteAll();
        var row = new MobileMenuSettings(); row.setId(1);
        row.setModulesJson(json.writeValueAsString(MobileMenuService.defaults()));
        row.setUpdatedAt(LocalDateTime.now()); repository.saveAndFlush(row);
    }
    @Test void readRequiresLoginButNotFitnessOrAdminPermission() throws Exception {
        mvc.perform(get("/api/mobile-menu")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/mobile-menu").with(user("regular").roles("USER")))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.modules.length()").value(13));
    }
    @Test void onlyAdminCanWriteGlobalMenu() throws Exception {
        var request = new MobileMenuService.Menu(service.get().version(), MobileMenuService.defaults());
        mvc.perform(put("/api/admin/mobile-menu").with(user("regular").roles("USER"))
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(request)))
                .andExpect(status().isForbidden());
        mvc.perform(put("/api/admin/mobile-menu").with(user("admin").roles("ADMIN"))
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(request)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.version").value(1));
    }
    @Test void supportsAllHiddenReorderingAndAuditWithoutChangingUserPermissions() {
        var input = new ArrayList<>(MobileMenuService.defaults()); Collections.reverse(input);
        var hidden = input.stream().map(e -> new MobileMenuService.Entry(e.key(), false)).toList();
        var result = service.update(new MobileMenuService.Menu(service.get().version(), hidden), "admin-id");
        assertEquals(hidden, result.modules());
        assertTrue(result.modules().stream().noneMatch(MobileMenuService.Entry::visible));
        assertEquals("admin-id", repository.findById(1).orElseThrow().getUpdatedBy());
        assertEquals(result, service.get());
    }
    @Test void staleVersionRejectsRatherThanOverwritingAnotherAdmin() {
        long old = service.get().version();
        service.update(new MobileMenuService.Menu(old, MobileMenuService.defaults()), "first");
        var error = assertThrows(ResponseStatusException.class, () ->
                service.update(new MobileMenuService.Menu(old, MobileMenuService.defaults()), "second"));
        assertEquals(409, error.getStatusCode().value());
        assertEquals("first", repository.findById(1).orElseThrow().getUpdatedBy());
    }
    @Test void rejectsMissingDuplicateUnknownAndNullValues() {
        var defaults = MobileMenuService.defaults();
        assertThrows(IllegalArgumentException.class, () -> service.update(new MobileMenuService.Menu(0L, defaults.subList(1, 13)), "a"));
        var duplicate = new ArrayList<>(defaults); duplicate.set(0, defaults.get(1));
        assertThrows(IllegalArgumentException.class, () -> service.update(new MobileMenuService.Menu(0L, duplicate), "a"));
        duplicate.set(0, new MobileMenuService.Entry("secret", true));
        assertThrows(IllegalArgumentException.class, () -> service.update(new MobileMenuService.Menu(0L, duplicate), "a"));
        duplicate.set(0, new MobileMenuService.Entry("dashboard", null));
        assertThrows(IllegalArgumentException.class, () -> service.update(new MobileMenuService.Menu(0L, duplicate), "a"));
    }
    @Test void invalidHttpPayloadReturnsBadRequest() throws Exception {
        mvc.perform(put("/api/admin/mobile-menu").with(user("admin").roles("ADMIN"))
                .contentType(MediaType.APPLICATION_JSON).content("{\"version\":0,\"modules\":[]}"))
                .andExpect(status().isBadRequest());
    }
    @Test void missingConfigDoesNotSilentlyReenableHiddenModulesOrAllowBootstrapRaces() {
        repository.deleteAll(); repository.flush();
        assertEquals(503, assertThrows(ResponseStatusException.class, service::get).getStatusCode().value());
        assertEquals(503, assertThrows(ResponseStatusException.class, () -> service.update(
                new MobileMenuService.Menu(0L, MobileMenuService.defaults()), "a")).getStatusCode().value());
    }
}
