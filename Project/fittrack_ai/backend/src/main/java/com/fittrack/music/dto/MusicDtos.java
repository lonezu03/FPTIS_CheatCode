package com.fittrack.music.dto;

import com.fittrack.music.entity.MusicInstrument;
import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public final class MusicDtos {
    private MusicDtos() {
    }

    public record CreateSessionRequest(
            @NotNull(message = "Chọn nhạc cụ")
            MusicInstrument instrument,
            @NotNull(message = "Chọn ngày luyện tập")
            LocalDate practicedOn,
            @NotNull(message = "Nhập số phút luyện tập")
            @Min(value = 1, message = "Số phút luyện tập từ 1 đến 600")
            @Max(value = 600, message = "Số phút luyện tập từ 1 đến 600")
            Integer minutes,
            @NotBlank(message = "Chọn bài tập")
            @Size(max = 60, message = "Mã bài tập tối đa 60 ký tự")
            @Pattern(regexp = "[a-z0-9-]+", message = "Mã bài tập chỉ gồm chữ thường, số và dấu gạch ngang")
            String exerciseKey,
            @Min(value = 20, message = "Nhịp độ (BPM) từ 20 đến 300")
            @Max(value = 300, message = "Nhịp độ (BPM) từ 20 đến 300")
            Integer bpm,
            @Size(max = 500, message = "Ghi chú tối đa 500 ký tự")
            String note
    ) {
    }

    public record SessionResponse(
            String id,
            MusicInstrument instrument,
            LocalDate practicedOn,
            int minutes,
            String exerciseKey,
            Integer bpm,
            String note,
            LocalDateTime createdAt
    ) {
    }

    public record DayMinutes(LocalDate date, long guitarMinutes, long fluteMinutes) {
    }

    public record BestBpm(String exerciseKey, MusicInstrument instrument, int bpm, LocalDate practicedOn) {
    }

    public record SummaryResponse(
            int streakDays,
            long todayMinutes,
            long weekMinutes,
            List<DayMinutes> weekByDay,
            Map<MusicInstrument, Long> totalMinutesByInstrument,
            long sessionsCount,
            List<BestBpm> bestBpmByExercise
    ) {
    }
}
