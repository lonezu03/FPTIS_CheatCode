package com.fittrack.quote.service;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.quote.dto.QuoteDtos.*;
import com.fittrack.quote.entity.*;
import com.fittrack.quote.repository.DailyQuoteDisplayRepository;
import com.fittrack.quote.repository.FavoriteQuoteRepository;
import com.fittrack.quote.repository.QuoteTagRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.Normalizer;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

@Service
@RequiredArgsConstructor
public class QuoteService {
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final FavoriteQuoteRepository quoteRepository;
    private final QuoteTagRepository tagRepository;
    private final DailyQuoteDisplayRepository displayRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public PageResponse<QuoteResponse> getMine(
            User user,
            String query,
            String tag,
            QuoteStatus status,
            int page,
            int size
    ) {
        var result = quoteRepository.search(
                user,
                cleanSearch(query),
                normalizeTag(tag),
                status,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
        ).map(this::toResponse);
        return PageResponse.from(result);
    }

    @Transactional(readOnly = true)
    public QuoteDetailResponse getDetail(User user, String id) {
        FavoriteQuote quote = requireOwned(user, id);
        return new QuoteDetailResponse(
                toResponse(quote),
                displayRepository.findDisplayDates(user, quote)
        );
    }

    @Transactional
    public QuoteResponse create(User user, QuoteRequest request) {
        String content = requireContent(request.content());
        String hash = contentHash(content);
        rejectDuplicate(user, hash, null, request.allowDuplicate());

        FavoriteQuote quote = FavoriteQuote.builder()
                .user(user)
                .content(content)
                .contentHash(hash)
                .status(QuoteStatus.ACTIVE)
                .build();
        applyRequest(user, quote, request);
        return toResponse(quoteRepository.save(quote));
    }

    @Transactional
    public QuoteResponse update(User user, String id, QuoteRequest request) {
        FavoriteQuote quote = requireOwned(user, id);
        String content = requireContent(request.content());
        String hash = contentHash(content);
        rejectDuplicate(user, hash, id, request.allowDuplicate());

        quote.setContent(content);
        quote.setContentHash(hash);
        applyRequest(user, quote, request);
        return toResponse(quoteRepository.save(quote));
    }

    @Transactional
    public QuoteResponse archive(User user, String id) {
        FavoriteQuote quote = requireOwned(user, id);
        quote.setStatus(QuoteStatus.ARCHIVED);
        quote.setArchivedAt(LocalDateTime.now());
        return toResponse(quoteRepository.save(quote));
    }

    @Transactional
    public QuoteResponse restore(User user, String id) {
        FavoriteQuote quote = requireOwned(user, id);
        quote.setStatus(QuoteStatus.ACTIVE);
        quote.setArchivedAt(null);
        return toResponse(quoteRepository.save(quote));
    }

    @Transactional
    public void delete(User user, String id) {
        FavoriteQuote quote = requireOwned(user, id);
        displayRepository.deleteByUserAndQuote(user, quote);
        quoteRepository.delete(quote);
    }

    @Transactional(readOnly = true)
    public DuplicateCheckResponse checkDuplicate(
            User user,
            DuplicateCheckRequest request
    ) {
        String hash = contentHash(requireContent(request.content()));
        Optional<FavoriteQuote> duplicate = duplicate(user, hash, request.excludedId());
        return new DuplicateCheckResponse(
                duplicate.isPresent(),
                duplicate.map(this::toResponse).orElse(null)
        );
    }

    @Transactional
    public DailyQuoteResponse getToday(User principal) {
        User user = userRepository.findByIdForUpdate(principal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản"));
        LocalDate today = LocalDate.now(VIETNAM_ZONE);

        Optional<DailyQuoteDisplay> existing = displayRepository.findByUserAndDisplayDate(user, today);
        if (existing.isPresent()) {
            FavoriteQuote quote = existing.get().getQuote();
            if (quote.getStatus() == QuoteStatus.ACTIVE && Boolean.TRUE.equals(quote.getIncludeInDaily())) {
                return new DailyQuoteResponse(today, toResponse(quote));
            }
            displayRepository.delete(existing.get());
            displayRepository.flush();
        }

        if (quoteRepository.countByUserAndStatusAndIncludeInDailyTrue(user, QuoteStatus.ACTIVE) == 0) {
            return new DailyQuoteResponse(today, null);
        }

        int cycle = Math.max(displayRepository.findCurrentCycle(user), 1);
        List<FavoriteQuote> candidates = quoteRepository.findDailyCandidates(user, cycle);
        if (candidates.isEmpty()) {
            cycle += 1;
            candidates = quoteRepository.findDailyCandidates(user, cycle);
        }

        FavoriteQuote selected = candidates.get(ThreadLocalRandom.current().nextInt(candidates.size()));
        DailyQuoteDisplay display = DailyQuoteDisplay.builder()
                .user(user)
                .quote(selected)
                .displayDate(today)
                .cycleNumber(cycle)
                .build();
        displayRepository.save(display);
        return new DailyQuoteResponse(today, toResponse(selected));
    }

    @Transactional(readOnly = true)
    public PageResponse<QuoteHistoryResponse> getHistory(User user, int page, int size) {
        var result = displayRepository.findByUserOrderByDisplayDateDesc(
                user,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
        ).map(display -> new QuoteHistoryResponse(
                display.getId(),
                display.getDisplayDate(),
                display.getCycleNumber(),
                toResponse(display.getQuote())
        ));
        return PageResponse.from(result);
    }

    @Transactional(readOnly = true)
    public List<String> getTags(User user) {
        return tagRepository.findByUserOrderByNameAsc(user).stream()
                .map(QuoteTag::getName)
                .toList();
    }

    private void applyRequest(User user, FavoriteQuote quote, QuoteRequest request) {
        validateSourceUrl(request.sourceUrl());
        quote.setAuthor(cleanOptional(request.author()));
        quote.setSourceType(request.sourceType());
        quote.setSourceTitle(cleanOptional(request.sourceTitle()));
        quote.setSourceUrl(cleanOptional(request.sourceUrl()));
        quote.setSourceLocation(cleanOptional(request.sourceLocation()));
        quote.setPersonalNote(cleanOptional(request.personalNote()));
        quote.setIncludeInDaily(request.includeInDaily() == null || request.includeInDaily());
        quote.setLanguage(cleanOptional(request.language()));
        quote.setTags(resolveTags(user, request.tags()));
    }

    private Set<QuoteTag> resolveTags(User user, List<String> rawTags) {
        if (rawTags == null || rawTags.isEmpty()) return new LinkedHashSet<>();
        LinkedHashSet<String> names = new LinkedHashSet<>();
        for (String rawTag : rawTags) {
            String name = normalizeTag(rawTag);
            if (name.isBlank()) continue;
            if (name.length() > 80) {
                throw new IllegalArgumentException("Mỗi nhãn tối đa 80 ký tự");
            }
            names.add(name);
        }
        if (names.size() > 10) {
            throw new IllegalArgumentException("Mỗi câu có tối đa 10 nhãn");
        }
        LinkedHashSet<QuoteTag> tags = new LinkedHashSet<>();
        for (String name : names) {
            QuoteTag tag = tagRepository.findByUserAndName(user, name)
                    .orElseGet(() -> tagRepository.save(QuoteTag.builder()
                            .user(user)
                            .name(name)
                            .build()));
            tags.add(tag);
        }
        return tags;
    }

    private void rejectDuplicate(
            User user,
            String hash,
            String excludedId,
            Boolean allowDuplicate
    ) {
        if (Boolean.TRUE.equals(allowDuplicate)) return;
        if (duplicate(user, hash, excludedId).isPresent()) {
            throw new ConflictException("Bạn đã lưu câu nói này trước đó");
        }
    }

    private Optional<FavoriteQuote> duplicate(User user, String hash, String excludedId) {
        if (excludedId == null || excludedId.isBlank()) {
            return quoteRepository.findFirstByUserAndContentHashOrderByCreatedAtAsc(user, hash);
        }
        return quoteRepository.findFirstByUserAndContentHashAndIdNotOrderByCreatedAtAsc(
                user,
                hash,
                excludedId
        );
    }

    private FavoriteQuote requireOwned(User user, String id) {
        return quoteRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy câu nói"));
    }

    private QuoteResponse toResponse(FavoriteQuote quote) {
        return new QuoteResponse(
                quote.getId(),
                quote.getContent(),
                quote.getAuthor(),
                quote.getSourceType(),
                quote.getSourceTitle(),
                quote.getSourceUrl(),
                quote.getSourceLocation(),
                quote.getPersonalNote(),
                Boolean.TRUE.equals(quote.getIncludeInDaily()),
                quote.getStatus(),
                quote.getLanguage(),
                quote.getTags().stream().map(QuoteTag::getName).sorted().toList(),
                quote.getCreatedAt(),
                quote.getUpdatedAt(),
                quote.getArchivedAt()
        );
    }

    private String requireContent(String value) {
        String content = value == null ? "" : value.strip()
                .replace("\r\n", "\n")
                .replace('\r', '\n');
        if (content.isBlank()) throw new IllegalArgumentException("Câu nói không được để trống");
        return content;
    }

    private String cleanSearch(String value) {
        return value == null ? "" : value.trim();
    }

    private String cleanOptional(String value) {
        if (value == null) return null;
        String cleaned = value.trim();
        return cleaned.isEmpty() ? null : cleaned;
    }

    private String normalizeTag(String value) {
        if (value == null) return "";
        String normalized = value.trim().replaceFirst("^#+", "").replaceAll("\\s+", "-");
        return normalized.toLowerCase(Locale.ROOT);
    }

    private String contentHash(String content) {
        String normalized = Normalizer.normalize(content, Normalizer.Form.NFKC)
                .trim()
                .toLowerCase(Locale.ROOT)
                .replaceAll("\\s+", " ");
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(normalized.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("Thiết bị không hỗ trợ SHA-256", ex);
        }
    }

    private void validateSourceUrl(String value) {
        String sourceUrl = cleanOptional(value);
        if (sourceUrl == null) return;
        try {
            URI uri = URI.create(sourceUrl);
            if (!("http".equalsIgnoreCase(uri.getScheme()) || "https".equalsIgnoreCase(uri.getScheme()))) {
                throw new IllegalArgumentException("Đường dẫn nguồn phải bắt đầu bằng http:// hoặc https://");
            }
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Đường dẫn nguồn không hợp lệ");
        }
    }
}
