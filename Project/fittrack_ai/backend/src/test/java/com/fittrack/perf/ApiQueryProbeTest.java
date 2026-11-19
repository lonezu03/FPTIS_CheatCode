package com.fittrack.perf;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.user.repository.UserRepository;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/**
 * Đo số câu SQL và thời gian của các API GET ở hai mức dữ liệu. API có số câu
 * tăng theo lượng dữ liệu là dấu hiệu N+1. Chạy thủ công:
 * {@code mvnw test -Dtest=ApiQueryProbeTest -Dperf.probe=true}
 */
@SpringBootTest(classes = FittrackBackendApplication.class,
        properties = "spring.jpa.properties.hibernate.generate_statistics=true")
@ActiveProfiles("test")
@EnabledIfSystemProperty(named = "perf.probe", matches = "true")
class ApiQueryProbeTest {

    static final List<String> ENDPOINTS = List.of(
            "/api/users/me", "/api/mobile-menu", "/api/notifications",
            "/api/dashboard/today", "/api/dashboard/progress", "/api/achievements/summary",
            "/api/health-management/summary", "/api/reports/weekly", "/api/recommendations/weekly",
            "/api/recommendations/check-ins/current", "/api/personal-reports/monthly?month=" + LocalDate.now().withDayOfMonth(1) + "&sections=NUTRITION,TRAINING,HABITS,FINANCE,FOCUS",
            "/api/todos", "/api/todos/page", "/api/todos/focus?from=" + LocalDate.now().minusDays(30) + "&to=" + LocalDate.now(), "/api/todos/focus/active",
            "/api/schedule", "/api/schedule/calendar?from=" + LocalDate.now().minusDays(30).atStartOfDay() + "&to=" + LocalDate.now().plusDays(60).atStartOfDay(),
            "/api/reminders",
            "/api/finance/accounts", "/api/finance/categories", "/api/finance/transactions",
            "/api/finance/budgets", "/api/finance/dashboard", "/api/finance/recurring",
            "/api/finance/reports/monthly", "/api/finance/savings", "/api/finance/shared/groups",
            "/api/finance/shared/invitations",
            "/api/journal", "/api/journal/entries", "/api/journal/today", "/api/journal/stats",
            "/api/journal/tags", "/api/journal/on-this-day", "/api/journal/settings", "/api/journal/packs",
            "/api/journal/prompts", "/api/journal/lock/status",
            "/api/quotes", "/api/quotes/today", "/api/quotes/history", "/api/quote-tags",
            "/api/foods", "/api/foods/page", "/api/foods/mine", "/api/exercises", "/api/exercises/page",
            "/api/exercises/mine", "/api/exercises/facets",
            "/api/nutrition/diary", "/api/nutrition/meal-logs", "/api/nutrition/meal-logs/page",
            "/api/nutrition/water-logs", "/api/nutrition/convenience", "/api/nutrition/foods/page",
            "/api/nutrition/pantry", "/api/nutrition/pantry/suggestions", "/api/nutrition/planning/meals",
            "/api/nutrition/planning/summary", "/api/nutrition/planning/groceries",
            "/api/nutrition/purchase-prices", "/api/nutrition/purchase-prices/week-cost?week=" + LocalDate.now().with(java.time.DayOfWeek.MONDAY) + "&referenceDate=" + LocalDate.now(),
            "/api/body-measurements", "/api/body-measurements/page", "/api/progress-photos",
            "/api/workouts/sessions", "/api/workouts/sessions/page", "/api/workouts/sessions/history",
            "/api/workouts/exercises", "/api/workouts/weekly-volume",
            "/api/workouts/exercise-preferences",
            "/api/workout-plans", "/api/workout-plans/page", "/api/workout-plans/cycles",
            "/api/workout-plans/appointments?from=" + LocalDate.now().minusDays(30).atStartOfDay() + "&to=" + LocalDate.now().plusDays(30).atStartOfDay(),
            "/api/template-shares",
            "/api/lunch/today", "/api/lunch/people", "/api/lunch/orders/history", "/api/lunch/orders/history/page",
            "/api/lunch/wallet/transactions", "/api/lunch/wallet/transactions/page",
            "/api/lunch/payment-requests/mine", "/api/lunch/payment-settings", "/api/lunch/notifications",
            "/api/lunch/notifications/page",
            "/api/lunch/admin/menus", "/api/lunch/admin/members", "/api/lunch/admin/payment-requests",
            "/api/admin/users", "/api/admin/users/page", "/api/admin/audit-events",
            "/api/admin/journal/prompts", "/api/admin/journal/prompts/packs",
            "/api/admin/notification-playbooks", "/api/assistant/privacy");

    @Autowired WebApplicationContext context;
    @Autowired UserRepository users;
    @Autowired EntityManagerFactory emf;
    @Autowired ObjectMapper json;

    MockMvc mvc;
    String token;
    String accountId;
    String expenseCategory;
    String incomeCategory;

    @Test
    void probe() throws Exception {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.setStatisticsEnabled(true);
        token = login();

        seed(1);
        var small = measure(stats);
        seed(2);
        var large = measure(stats);

        var out = new StringBuilder("endpoint\tstatus\tsql@1x\tsql@2x\tms@2x\n");
        ENDPOINTS.stream()
                .sorted(Comparator.comparingLong((String e) -> -large.get(e)[1]))
                .forEach(e -> out.append(e).append('\t').append(large.get(e)[0]).append('\t')
                        .append(small.get(e)[1]).append('\t').append(large.get(e)[1]).append('\t')
                        .append(large.get(e)[2]).append('\n'));
        Path file = Path.of("target", "api-query-probe.tsv");
        Files.writeString(file, out.toString());
        System.out.println(out);
    }

    Map<String, long[]> measure(Statistics stats) throws Exception {
        Map<String, long[]> result = new LinkedHashMap<>();
        for (String endpoint : ENDPOINTS) {
            mvc.perform(get(endpoint).header("Authorization", "Bearer " + token)); // warm-up
            stats.clear();
            long start = System.nanoTime();
            var response = mvc.perform(get(endpoint).header("Authorization", "Bearer " + token))
                    .andReturn().getResponse();
            int status = response.getStatus();
            if (status >= 400) System.out.println("GET " + endpoint + " -> " + status + " " + response.getContentAsString().lines().findFirst().orElse(""));
            long ms = (System.nanoTime() - start) / 1_000_000;
            result.put(endpoint, new long[]{status, stats.getPrepareStatementCount(), ms});
        }
        return result;
    }

    String login() throws Exception {
        String email = "probe@example.com";
        String password = "Probe@12345";
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(
                Map.of("email", email, "password", password, "fullName", "Probe User", "gender", "MALE"))));
        var user = users.findByEmail(email).orElseThrow();
        user.setRole("ADMIN");
        user.setEmailVerified(true);
        user.setLunchEnabled(true); user.setFitnessEnabled(true); user.setHealthEnabled(true);
        user.setChatbotEnabled(true); user.setTodoEnabled(true); user.setScheduleEnabled(true);
        user.setQuoteEnabled(true); user.setFinanceEnabled(true); user.setJournalEnabled(true);
        user.setPasswordChangeRequired(false);
        users.saveAndFlush(user);
        String body = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(
                Map.of("email", email, "password", password)))).andReturn().getResponse().getContentAsString();
        return json.readTree(body).get("token").asText();
    }

    void seed(int round) throws Exception {
        send("/api/demo/seed", Map.of());
        if (accountId == null) {
            JsonNode account = send("/api/finance/accounts", Map.of("name", "Ví", "accountType", "CASH",
                    "currencyCode", "VND", "openingBalance", 1_000_000));
            accountId = account == null ? null : account.path("id").asText(null);
            var categories = json.readTree(mvc.perform(get("/api/finance/categories").header("Authorization", "Bearer " + token))
                    .andReturn().getResponse().getContentAsString());
            for (JsonNode c : categories) {
                if (expenseCategory == null && "EXPENSE".equals(c.path("transactionKind").asText())) expenseCategory = c.path("id").asText();
                if (incomeCategory == null && "INCOME".equals(c.path("transactionKind").asText())) incomeCategory = c.path("id").asText();
            }
        }
        LocalDateTime now = LocalDateTime.now().withNano(0);
        for (int i = 0; i < 20; i++) {
            String tag = round + "-" + i;
            send("/api/todos", Map.of("title", "Việc " + tag, "startAt", now.plusHours(i).toString(),
                    "dueAt", now.plusHours(i + 1).toString()));
            send("/api/schedule", Map.of("title", "Lịch " + tag, "startAt", now.plusDays(i % 10).toString(),
                    "endAt", now.plusDays(i % 10).plusHours(1).toString()));
            if (accountId != null) {
                send("/api/finance/transactions", Map.of("type", i % 3 == 0 ? "INCOME" : "EXPENSE",
                        "amount", 10_000 + i, "accountId", accountId,
                        "categoryId", i % 3 == 0 ? incomeCategory : expenseCategory, "occurredAt", now.minusDays(i).toString(),
                        "merchant", "Shop " + tag));
            }
            send("/api/journal/entries", Map.of("origin", "FREEFORM", "entryDate", LocalDate.now().minusDays(i + 20L * (round - 1)).toString(),
                    "title", "Trang " + tag, "body", "Nội dung " + tag, "tags", List.of("tag" + (i % 4))));
            send("/api/quotes", Map.of("content", "Câu nói " + tag, "author", "Tác giả " + i));
        }
    }

    JsonNode send(String path, Object body) throws Exception {
        var response = mvc.perform(post(path).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(body))).andReturn().getResponse();
        if (response.getStatus() >= 300) {
            System.out.println("SEED " + path + " -> " + response.getStatus() + " " + response.getContentAsString().lines().findFirst().orElse(""));
            return null;
        }
        String text = response.getContentAsString();
        return text.isBlank() ? null : json.readTree(text);
    }
}
