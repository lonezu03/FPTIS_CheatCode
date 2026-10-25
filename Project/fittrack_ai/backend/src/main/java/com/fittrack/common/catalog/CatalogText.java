package com.fittrack.common.catalog;

import java.text.Normalizer;
import java.util.Locale;
import org.springframework.data.jpa.domain.Specification;

/** Shared literal, accent-insensitive AND-token catalog matching. */
public final class CatalogText {
    private CatalogText() {}

    public static String normalize(String value) {
        return Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "").replace('đ', 'd').replace('Đ', 'D')
                .toLowerCase(Locale.ROOT).trim().replaceAll("\\s+", " ");
    }

    public static String muscle(String value) {
        if (value == null) return null;
        return switch (normalize(value)) {
            case "nguc", "chest" -> "Chest";
            case "lung", "back" -> "Back";
            case "vai", "shoulders", "shoulder" -> "Shoulders";
            case "chan", "legs" -> "Legs";
            case "tay truoc", "biceps", "bicep" -> "Biceps";
            case "tay sau", "triceps", "tricep" -> "Triceps";
            case "bung", "core", "abs" -> "Core";
            case "mong", "glutes" -> "Glutes";
            case "dui truoc", "quadriceps", "quads" -> "Quadriceps";
            case "dui sau", "hamstrings" -> "Hamstrings";
            case "bap chan", "calves" -> "Calves";
            case "dui trong", "adductors" -> "Adductors";
            case "toan than", "full body" -> "Full Body";
            default -> value.trim();
        };
    }

    public static String equipment(String value) {
        if (value == null) return null;
        return switch (normalize(value)) {
            case "ta don", "dumbbells", "dumbbell" -> "Dumbbell";
            case "ta don + ghe nghieng", "ta don va ghe nghieng" -> "Dumbbell + Incline Bench";
            case "ta don + ghe phang", "ta don va ghe phang" -> "Dumbbell + Flat Bench";
            case "ta don dai", "thanh don", "barbell" -> "Barbell";
            case "cap", "may cap", "cable", "cable machine" -> "Cable Machine";
            case "smith", "may smith", "smith machine" -> "Smith Machine";
            case "khong", "trong luong co the", "bodyweight" -> "Bodyweight";
            default -> value.trim();
        };
    }

    public static <T> Specification<T> search(String keyword, boolean includeInactive) {
        return (root, query, cb) -> {
            var conditions = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            if (!includeInactive) {
                conditions.add(cb.isTrue(root.get("active")));
                conditions.add(cb.equal(root.get("approvalStatus"), "APPROVED"));
            }
            for (String token : normalize(keyword).split(" ")) {
                if (token.isEmpty()) continue;
                String escaped = token.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
                conditions.add(cb.like(root.get("searchText"), "%" + escaped + "%", '\\'));
            }
            return cb.and(conditions.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
    }
}
