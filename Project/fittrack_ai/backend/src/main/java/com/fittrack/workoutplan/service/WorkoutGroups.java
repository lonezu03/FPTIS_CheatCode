package com.fittrack.workoutplan.service;

import java.util.*;

/** Shared bounds and consistency rules; grouping never marks a set complete. */
public final class WorkoutGroups {
    private WorkoutGroups() {}
    public record Group(String key, String type, Integer rounds, Integer exerciseRest, Integer roundRest) {}
    public static void validate(List<Group> groups) {
        Map<String, Group> seen = new HashMap<>();
        for (Group g : groups) {
            if (g.key() == null || g.key().isBlank()) {
                if (g.type() != null || g.rounds() != null || g.exerciseRest() != null || g.roundRest() != null)
                    throw new IllegalArgumentException("Thông số nhóm cần mã nhóm");
                continue;
            }
            if (g.key().length() > 60 || !Set.of("SUPERSET", "CIRCUIT").contains(g.type() == null ? "" : g.type())
                    || g.rounds() == null || g.rounds() < 1 || g.rounds() > 20
                    || g.exerciseRest() == null || g.exerciseRest() < 0 || g.exerciseRest() > 1800
                    || g.roundRest() == null || g.roundRest() < 0 || g.roundRest() > 1800)
                throw new IllegalArgumentException("Nhóm bài phải có loại, 1–20 vòng và thời gian nghỉ hợp lệ");
            Group previous = seen.putIfAbsent(g.key(), g);
            if (previous != null && !previous.equals(g)) throw new IllegalArgumentException("Các bài cùng nhóm phải có cùng cấu hình vòng/nghỉ");
        }
    }
}
