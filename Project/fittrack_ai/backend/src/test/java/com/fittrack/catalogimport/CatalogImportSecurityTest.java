package com.fittrack.catalogimport;

import com.fittrack.FittrackBackendApplication;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
class CatalogImportSecurityTest {
    @Autowired WebApplicationContext context;
    MockMvc mvc;
    @BeforeEach void setup() { mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build(); }
    @Test void anonymousAndRegularUserCannotAccessImportTemplates() throws Exception {
        mvc.perform(get("/api/catalog-imports/EXERCISE/template")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/catalog-imports/EXERCISE/template").with(user("regular").roles("USER"))).andExpect(status().isForbidden());
        mvc.perform(get("/api/catalog-imports/FOOD/export").with(user("regular").roles("USER"))).andExpect(status().isForbidden());
    }
    @Test void adminCanDownloadTemplate() throws Exception {
        mvc.perform(get("/api/catalog-imports/FOOD/template").with(user("admin").roles("ADMIN"))).andExpect(status().isOk());
    }
}
