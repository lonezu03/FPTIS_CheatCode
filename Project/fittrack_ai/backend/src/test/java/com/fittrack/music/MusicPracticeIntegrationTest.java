package com.fittrack.music;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.music.entity.MusicInstrument;
import com.fittrack.music.entity.MusicPracticeSession;
import com.fittrack.music.repository.MusicPracticeSessionRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import tools.jackson.databind.ObjectMapper;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
@Transactional
class MusicPracticeIntegrationTest {
    private static final ZoneId ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    @Autowired WebApplicationContext context;
    @Autowired UserRepository users;
    @Autowired MusicPracticeSessionRepository sessions;
    @Autowired ObjectMapper json;
    MockMvc mvc;
    LocalDate today;

    @BeforeEach
    void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        today = LocalDate.now(ZONE);
    }

    private User newUser() {
        return users.saveAndFlush(User.builder().email(UUID.randomUUID() + "@example.test").password("encoded")
                .fullName("Music test").role("USER").active(true).build());
    }

    private RequestPostProcessor as(User user) {
        return authentication(new UsernamePasswordAuthenticationToken(
                user, null, List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole()))));
    }

    private Map<String, Object> body(String instrument, LocalDate on, Integer minutes, String key, Integer bpm, String note) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("instrument", instrument);
        m.put("practicedOn", on == null ? null : on.toString());
        m.put("minutes", minutes);
        m.put("exerciseKey", key);
        if (bpm != null) m.put("bpm", bpm);
        if (note != null) m.put("note", note);
        return m;
    }

    private String create(User user, Map<String, Object> body) throws Exception {
        String response = mvc.perform(post("/api/music/sessions").with(as(user))
                        .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(body)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(response).get("id").asString();
    }

    private void insert(User user, MusicInstrument instrument, LocalDate on, int minutes, String key, Integer bpm) {
        sessions.saveAndFlush(MusicPracticeSession.builder().user(user).instrument(instrument).practicedOn(on)
                .minutes(minutes).exerciseKey(key).bpm(bpm).build());
    }

    @Test
    void requiresAuthentication() throws Exception {
        mvc.perform(get("/api/music/summary")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/music/sessions")).andExpect(status().isUnauthorized());
    }

    @Test
    void createReturnsSessionJson() throws Exception {
        User user = newUser();
        mvc.perform(post("/api/music/sessions").with(as(user)).contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(body("FLUTE", today, 25, "flute-long-tone", 60, "  Hơi đều hơn  "))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.instrument").value("FLUTE"))
                .andExpect(jsonPath("$.practicedOn").value(today.toString()))
                .andExpect(jsonPath("$.minutes").value(25))
                .andExpect(jsonPath("$.exerciseKey").value("flute-long-tone"))
                .andExpect(jsonPath("$.bpm").value(60))
                .andExpect(jsonPath("$.note").value("Hơi đều hơn"))
                .andExpect(jsonPath("$.createdAt").isNotEmpty());

        mvc.perform(post("/api/music/sessions").with(as(user)).contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(body("GUITAR", today.minusDays(365), 600, "free", null, null))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bpm").doesNotExist());
    }

    @Test
    void invalidInputReturnsBadRequestWithVietnameseMessage() throws Exception {
        User user = newUser();
        List<Map<String, Object>> invalid = List.of(
                body(null, today, 10, "free", null, null),
                body("GUITAR", null, 10, "free", null, null),
                body("GUITAR", today, 0, "free", null, null),
                body("GUITAR", today, 601, "free", null, null),
                body("GUITAR", today, null, "free", null, null),
                body("GUITAR", today, 10, "", null, null),
                body("GUITAR", today, 10, "Guitar_Spider", null, null),
                body("GUITAR", today, 10, "a".repeat(61), null, null),
                body("GUITAR", today, 10, "free", 19, null),
                body("GUITAR", today, 10, "free", 301, null),
                body("GUITAR", today, 10, "free", null, "x".repeat(501)));
        for (Map<String, Object> b : invalid) {
            mvc.perform(post("/api/music/sessions").with(as(user)).contentType(MediaType.APPLICATION_JSON)
                            .content(json.writeValueAsString(b)))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.message").isNotEmpty());
        }
        mvc.perform(post("/api/music/sessions").with(as(user)).contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(body("GUITAR", today, 0, "free", null, null))))
                .andExpect(jsonPath("$.message").value(containsString("Số phút luyện tập")));
        mvc.perform(post("/api/music/sessions").with(as(user)).contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(body("GUITAR", today.plusDays(1), 10, "free", null, null))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Ngày luyện tập không được ở tương lai"));
        mvc.perform(post("/api/music/sessions").with(as(user)).contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(body("GUITAR", today.minusDays(366), 10, "free", null, null))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(containsString("365 ngày")));
        mvc.perform(post("/api/music/sessions").with(as(user)).contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(body("PIANO", today, 10, "free", null, null))))
                .andExpect(status().isBadRequest());
        assertEquals(0, sessions.count());
    }

    @Test
    void listFiltersOrdersPagesAndIsolatesUsers() throws Exception {
        User user = newUser();
        User other = newUser();
        String older = create(user, body("GUITAR", today.minusDays(3), 10, "guitar-spider", 80, null));
        String first = create(user, body("FLUTE", today, 15, "flute-long-tone", null, null));
        String second = create(user, body("GUITAR", today, 20, "guitar-chord-change", null, null));
        var firstEntity = sessions.findById(first).orElseThrow();
        firstEntity.setCreatedAt(LocalDateTime.now(ZONE).minusHours(1));
        sessions.saveAndFlush(firstEntity);
        create(other, body("GUITAR", today, 30, "free", null, null));

        mvc.perform(get("/api/music/sessions").with(as(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(3))
                .andExpect(jsonPath("$.size").value(20))
                .andExpect(jsonPath("$.content[0].id").value(second))
                .andExpect(jsonPath("$.content[1].id").value(first))
                .andExpect(jsonPath("$.content[2].id").value(older));

        mvc.perform(get("/api/music/sessions").with(as(user))
                        .param("from", today.minusDays(1).toString()).param("to", today.toString())
                        .param("instrument", "GUITAR").param("page", "0").param("size", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].id").value(second));

        mvc.perform(get("/api/music/sessions").with(as(user)).param("instrument", "").param("size", "2").param("page", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content.length()").value(1))
                .andExpect(jsonPath("$.totalPages").value(2));

        mvc.perform(get("/api/music/sessions").with(as(user))
                        .param("from", today.toString()).param("to", today.minusDays(1).toString()))
                .andExpect(status().isBadRequest());
        mvc.perform(get("/api/music/sessions").with(as(user)).param("from", "not-a-date"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void deleteOnlyOwnSession() throws Exception {
        User owner = newUser();
        User other = newUser();
        String id = create(owner, body("GUITAR", today, 10, "free", null, null));

        mvc.perform(delete("/api/music/sessions/" + id).with(as(other))).andExpect(status().isNotFound());
        assertTrue(sessions.existsById(id));
        mvc.perform(delete("/api/music/sessions/" + id).with(as(owner))).andExpect(status().isNoContent());
        assertFalse(sessions.existsById(id));
        mvc.perform(delete("/api/music/sessions/" + id).with(as(owner))).andExpect(status().isNotFound());
    }

    @Test
    void summaryAggregatesAndStreakIncludingToday() throws Exception {
        User user = newUser();
        User other = newUser();
        insert(user, MusicInstrument.GUITAR, today, 20, "guitar-spider", 70);
        insert(user, MusicInstrument.FLUTE, today, 15, "flute-long-tone", null);
        insert(user, MusicInstrument.GUITAR, today.minusDays(1), 10, "guitar-spider", 90);
        insert(user, MusicInstrument.FLUTE, today.minusDays(2), 5, "flute-scale-c", 60);
        insert(user, MusicInstrument.GUITAR, today.minusDays(4), 30, "guitar-spider", 90);
        insert(user, MusicInstrument.GUITAR, today.minusDays(10), 40, "free", 100);
        insert(user, MusicInstrument.FLUTE, today.minusDays(10), 25, "free", 50);
        insert(other, MusicInstrument.GUITAR, today, 99, "guitar-spider", 200);

        mvc.perform(get("/api/music/summary").with(as(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.streakDays").value(3))
                .andExpect(jsonPath("$.todayMinutes").value(35))
                .andExpect(jsonPath("$.weekMinutes").value(80))
                .andExpect(jsonPath("$.weekByDay.length()").value(7))
                .andExpect(jsonPath("$.weekByDay[0].date").value(today.minusDays(6).toString()))
                .andExpect(jsonPath("$.weekByDay[6].date").value(today.toString()))
                .andExpect(jsonPath("$.weekByDay[6].guitarMinutes").value(20))
                .andExpect(jsonPath("$.weekByDay[6].fluteMinutes").value(15))
                .andExpect(jsonPath("$.weekByDay[4].fluteMinutes").value(5))
                .andExpect(jsonPath("$.weekByDay[3].guitarMinutes").value(0))
                .andExpect(jsonPath("$.weekByDay[2].guitarMinutes").value(30))
                .andExpect(jsonPath("$.totalMinutesByInstrument.GUITAR").value(100))
                .andExpect(jsonPath("$.totalMinutesByInstrument.FLUTE").value(45))
                .andExpect(jsonPath("$.sessionsCount").value(7))
                .andExpect(jsonPath("$.bestBpmByExercise.length()").value(4))
                // ordered by instrument (GUITAR, FLUTE enum order) then exerciseKey
                .andExpect(jsonPath("$.bestBpmByExercise[0].exerciseKey").value("free"))
                .andExpect(jsonPath("$.bestBpmByExercise[0].instrument").value("GUITAR"))
                .andExpect(jsonPath("$.bestBpmByExercise[0].bpm").value(100))
                .andExpect(jsonPath("$.bestBpmByExercise[1].exerciseKey").value("guitar-spider"))
                .andExpect(jsonPath("$.bestBpmByExercise[1].bpm").value(90))
                .andExpect(jsonPath("$.bestBpmByExercise[1].practicedOn").value(today.minusDays(4).toString()))
                .andExpect(jsonPath("$.bestBpmByExercise[2].exerciseKey").value("flute-scale-c"))
                .andExpect(jsonPath("$.bestBpmByExercise[3].exerciseKey").value("free"))
                .andExpect(jsonPath("$.bestBpmByExercise[3].instrument").value("FLUTE"));
    }

    @Test
    void streakCountsUpToYesterdayWhenNothingTodayAndBreaksOnGap() throws Exception {
        User user = newUser();
        insert(user, MusicInstrument.FLUTE, today.minusDays(1), 10, "free", null);
        insert(user, MusicInstrument.FLUTE, today.minusDays(1), 10, "free", null);
        insert(user, MusicInstrument.GUITAR, today.minusDays(2), 10, "free", null);
        insert(user, MusicInstrument.GUITAR, today.minusDays(4), 10, "free", null);
        mvc.perform(get("/api/music/summary").with(as(user)))
                .andExpect(jsonPath("$.streakDays").value(2))
                .andExpect(jsonPath("$.todayMinutes").value(0));

        User stale = newUser();
        insert(stale, MusicInstrument.GUITAR, today.minusDays(2), 10, "free", null);
        mvc.perform(get("/api/music/summary").with(as(stale)))
                .andExpect(jsonPath("$.streakDays").value(0));

        User empty = newUser();
        mvc.perform(get("/api/music/summary").with(as(empty)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.streakDays").value(0))
                .andExpect(jsonPath("$.weekByDay.length()").value(7))
                .andExpect(jsonPath("$.totalMinutesByInstrument.GUITAR").value(0))
                .andExpect(jsonPath("$.totalMinutesByInstrument.FLUTE").value(0))
                .andExpect(jsonPath("$.sessionsCount").value(0))
                .andExpect(jsonPath("$.bestBpmByExercise.length()").value(0));
    }
}
