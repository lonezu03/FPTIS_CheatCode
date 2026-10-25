package com.fittrack.todo.service;

import com.fittrack.todo.entity.Todo;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.domain.Specification;
import java.time.LocalDateTime;
import java.util.Locale;

/** Owner-scoped planner filters, shared by paged results and counters. */
public final class TodoFilters {
    private TodoFilters() {}

    public static Specification<Todo> matching(User user, String view, String category,
                                               Todo.TodoStatus status, LocalDateTime now) {
        return (root, query, cb) -> {
            var predicates = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            predicates.add(cb.equal(root.get("user"), user));
            if (category != null && !category.isBlank()) {
                predicates.add(cb.equal(root.get("category"), Todo.TodoCategory.valueOf(category.toUpperCase(Locale.ROOT))));
            }
            if (status != null) predicates.add(cb.equal(root.get("status"), status));
            var active = root.get("status").in(Todo.TodoStatus.OPEN, Todo.TodoStatus.IN_PROGRESS);
            var date = cb.<LocalDateTime>coalesce(root.get("startAt"), root.get("dueAt"));
            var day = now.toLocalDate().atStartOfDay();
            var tomorrow = day.plusDays(1);
            switch (view == null ? "ALL" : view.toUpperCase(Locale.ROOT)) {
                case "TODAY" -> predicates.add(cb.or(
                        cb.and(cb.greaterThanOrEqualTo(date, day), cb.lessThan(date, tomorrow)),
                        cb.and(active, cb.lessThan(date, day)),
                        cb.and(cb.equal(root.get("status"), Todo.TodoStatus.DONE),
                                cb.greaterThanOrEqualTo(root.get("completedAt"), day),
                                cb.lessThan(root.get("completedAt"), tomorrow))));
                case "OVERDUE" -> predicates.add(cb.and(active, cb.lessThan(root.get("dueAt"), now)));
                case "UPCOMING" -> predicates.add(cb.and(active, cb.greaterThanOrEqualTo(date, tomorrow)));
                case "ALL" -> { }
                default -> throw new IllegalArgumentException("Chế độ xem công việc không hợp lệ");
            }
            return cb.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
    }
}
