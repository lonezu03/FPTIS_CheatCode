package com.fittrack.music.service;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.music.dto.MusicDtos.*;
import com.fittrack.music.entity.MusicInstrument;
import com.fittrack.music.entity.MusicPracticeSession;
import com.fittrack.music.repository.MusicPracticeSessionRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;

@Service
@RequiredArgsConstructor
public class MusicPracticeService {
    public static final ZoneId ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    static final int MAX_AGE_DAYS = 365;
    private static final LocalDate MIN_DATE = LocalDate.of(1900, 1, 1);
    private static final LocalDate MAX_DATE = LocalDate.of(9999, 12, 31);
    private static final Sort LIST_ORDER = Sort.by(
            Sort.Order.desc("practicedOn"), Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

    private final MusicPracticeSessionRepository sessions;

    LocalDate today() {
        return LocalDate.now(Clock.system(ZONE));
    }

    @Transactional
    public SessionResponse create(User user, CreateSessionRequest input) {
        LocalDate today = today();
        if (input.practicedOn().isAfter(today)) {
            throw new IllegalArgumentException("Ngày luyện tập không được ở tương lai");
        }
        if (input.practicedOn().isBefore(today.minusDays(MAX_AGE_DAYS))) {
            throw new IllegalArgumentException("Chỉ ghi nhận buổi luyện tập trong vòng 365 ngày gần đây");
        }
        String note = input.note() == null || input.note().isBlank() ? null : input.note().trim();
        MusicPracticeSession saved = sessions.save(MusicPracticeSession.builder()
                .user(user)
                .instrument(input.instrument())
                .practicedOn(input.practicedOn())
                .minutes(input.minutes())
                .exerciseKey(input.exerciseKey())
                .bpm(input.bpm())
                .note(note)
                .build());
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public PageResponse<SessionResponse> list(
            User user, LocalDate from, LocalDate to, MusicInstrument instrument, int page, int size) {
        LocalDate start = from == null ? MIN_DATE : from;
        LocalDate end = to == null ? MAX_DATE : to;
        if (end.isBefore(start)) {
            throw new IllegalArgumentException("Ngày kết thúc phải sau hoặc bằng ngày bắt đầu");
        }
        PageRequest pageable = PageRequest.of(Math.max(0, page), Math.clamp(size, 1, 100), LIST_ORDER);
        var result = instrument == null
                ? sessions.findByUserIdAndPracticedOnBetween(user.getId(), start, end, pageable)
                : sessions.findByUserIdAndInstrumentAndPracticedOnBetween(user.getId(), instrument, start, end, pageable);
        return PageResponse.from(result.map(this::toResponse));
    }

    @Transactional
    public void delete(User user, String id) {
        MusicPracticeSession session = sessions.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy buổi luyện tập của bạn"));
        sessions.delete(session);
    }

    @Transactional(readOnly = true)
    public SummaryResponse summary(User user) {
        String userId = user.getId();
        LocalDate today = today();
        LocalDate weekStart = today.minusDays(6);

        Map<LocalDate, long[]> byDay = new HashMap<>();
        for (Object[] row : sessions.sumMinutesByDayAndInstrument(userId, weekStart, today)) {
            long[] minutes = byDay.computeIfAbsent((LocalDate) row[0], d -> new long[2]);
            minutes[((MusicInstrument) row[1]).ordinal()] += ((Number) row[2]).longValue();
        }
        List<DayMinutes> weekByDay = new ArrayList<>(7);
        long weekMinutes = 0;
        for (int i = 0; i < 7; i++) {
            LocalDate date = weekStart.plusDays(i);
            long[] minutes = byDay.getOrDefault(date, new long[2]);
            long guitar = minutes[MusicInstrument.GUITAR.ordinal()];
            long flute = minutes[MusicInstrument.FLUTE.ordinal()];
            weekByDay.add(new DayMinutes(date, guitar, flute));
            weekMinutes += guitar + flute;
        }
        DayMinutes todayRow = weekByDay.get(6);
        long todayMinutes = todayRow.guitarMinutes() + todayRow.fluteMinutes();

        Map<MusicInstrument, Long> totals = new EnumMap<>(MusicInstrument.class);
        for (MusicInstrument instrument : MusicInstrument.values()) totals.put(instrument, 0L);
        long sessionsCount = 0;
        for (Object[] row : sessions.totalsByInstrument(userId)) {
            totals.put((MusicInstrument) row[0], ((Number) row[1]).longValue());
            sessionsCount += ((Number) row[2]).longValue();
        }

        List<BestBpm> best = sessions.bestBpmByExercise(userId).stream()
                .map(row -> new BestBpm((String) row[0], (MusicInstrument) row[1],
                        ((Number) row[2]).intValue(), (LocalDate) row[3]))
                .sorted(Comparator.comparing(BestBpm::instrument).thenComparing(BestBpm::exerciseKey))
                .toList();

        return new SummaryResponse(
                streak(sessions.practiceDatesUpTo(userId, today), today),
                todayMinutes, weekMinutes, weekByDay, totals, sessionsCount, best);
    }

    /** Dates are distinct, sorted descending and not after today. */
    static int streak(List<LocalDate> dates, LocalDate today) {
        if (dates.isEmpty()) return 0;
        LocalDate expected = dates.getFirst().equals(today) ? today : today.minusDays(1);
        int count = 0;
        for (LocalDate date : dates) {
            if (!date.equals(expected)) break;
            count++;
            expected = expected.minusDays(1);
        }
        return count;
    }

    private SessionResponse toResponse(MusicPracticeSession s) {
        return new SessionResponse(s.getId(), s.getInstrument(), s.getPracticedOn(), s.getMinutes(),
                s.getExerciseKey(), s.getBpm(), s.getNote(), s.getCreatedAt());
    }
}
