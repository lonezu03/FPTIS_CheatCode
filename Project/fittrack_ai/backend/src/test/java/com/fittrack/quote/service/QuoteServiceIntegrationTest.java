package com.fittrack.quote.service;

import com.fittrack.FittrackBackendApplication;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.quote.dto.QuoteDtos.DuplicateCheckRequest;
import com.fittrack.quote.dto.QuoteDtos.QuoteRequest;
import com.fittrack.quote.entity.DailyQuoteDisplay;
import com.fittrack.quote.entity.QuoteSourceType;
import com.fittrack.quote.entity.QuoteStatus;
import com.fittrack.quote.repository.DailyQuoteDisplayRepository;
import com.fittrack.quote.repository.FavoriteQuoteRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes = FittrackBackendApplication.class)
@ActiveProfiles("test")
class QuoteServiceIntegrationTest {
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    @Autowired
    private QuoteService quoteService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FavoriteQuoteRepository quoteRepository;

    @Autowired
    private DailyQuoteDisplayRepository displayRepository;

    @Test
    void storesMetadataSearchesTagsAndWarnsAboutNormalizedDuplicates() {
        User user = saveUser("quote-metadata");
        var created = quoteService.create(user, request(
                "  Thượng thiện   nhược thủy  ",
                "Lão Tử",
                List.of("Triết lý", "#Đạo-gia"),
                false
        ));

        assertEquals("Thượng thiện   nhược thủy", created.content());
        assertEquals(List.of("triết-lý", "đạo-gia"), created.tags());
        assertEquals(1, quoteService.getMine(user, "Lão Tử", "đạo-gia", QuoteStatus.ACTIVE, 0, 20)
                .totalElements());

        var duplicate = quoteService.checkDuplicate(
                user,
                new DuplicateCheckRequest("THƯỢNG THIỆN NHƯỢC THỦY", null)
        );
        assertTrue(duplicate.duplicate());
        assertEquals(created.id(), duplicate.existingQuote().id());
        assertThrows(
                ConflictException.class,
                () -> quoteService.create(user, request(
                        "thượng thiện nhược thủy",
                        null,
                        List.of(),
                        false
                ))
        );

        assertDoesNotThrow(() -> quoteService.create(user, request(
                "thượng thiện nhược thủy",
                null,
                List.of(),
                true
        )));
    }

    @Test
    void dailyQuoteIsStableAndDoesNotRepeatBeforeCycleEnds() {
        User user = saveUser("quote-cycle");
        var first = quoteService.create(user, request("Câu A", null, List.of(), false));
        var second = quoteService.create(user, request("Câu B", null, List.of(), false));
        var third = quoteService.create(user, request("Câu C", null, List.of(), false));
        LocalDate today = LocalDate.now(VIETNAM_ZONE);

        displayRepository.save(DailyQuoteDisplay.builder()
                .user(user)
                .quote(quoteRepository.findById(first.id()).orElseThrow())
                .displayDate(today.minusDays(2))
                .cycleNumber(1)
                .build());
        displayRepository.save(DailyQuoteDisplay.builder()
                .user(user)
                .quote(quoteRepository.findById(second.id()).orElseThrow())
                .displayDate(today.minusDays(1))
                .cycleNumber(1)
                .build());

        var daily = quoteService.getToday(user);
        assertEquals(third.id(), daily.quote().id());
        assertEquals(third.id(), quoteService.getToday(user).quote().id());

        quoteService.archive(user, third.id());
        var replacement = quoteService.getToday(user);
        assertNotNull(replacement.quote());
        assertNotEquals(third.id(), replacement.quote().id());
    }

    @Test
    void quotesArePrivateAndDeleteRemovesDisplayHistory() {
        User owner = saveUser("quote-owner");
        User other = saveUser("quote-other");
        var created = quoteService.create(owner, request("Câu riêng tư", null, List.of(), false));
        quoteService.getToday(owner);

        assertEquals(0, quoteService.getMine(other, "", "", null, 0, 20).totalElements());
        assertThrows(RuntimeException.class, () -> quoteService.getDetail(other, created.id()));

        quoteService.delete(owner, created.id());
        assertFalse(quoteRepository.existsById(created.id()));
        assertEquals(0, quoteService.getHistory(owner, 0, 20).totalElements());
    }

    private QuoteRequest request(
            String content,
            String author,
            List<String> tags,
            boolean allowDuplicate
    ) {
        return new QuoteRequest(
                content,
                author,
                QuoteSourceType.BOOK,
                "Nguồn thử nghiệm",
                "https://example.com/source",
                "Chương 1",
                "Ghi chú cá nhân",
                true,
                "vi",
                tags,
                allowDuplicate
        );
    }

    private User saveUser(String prefix) {
        return userRepository.save(User.builder()
                .email(prefix + "-" + UUID.randomUUID() + "@example.com")
                .password("encoded-password")
                .fullName("Người dùng thử")
                .build());
    }
}
