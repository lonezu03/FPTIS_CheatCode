package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenu;
import com.fittrack.lunch.entity.LunchOrder;
import org.springframework.stereotype.Component;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
public class LunchTextFormatter {

    private static final DateTimeFormatter ORDER_DATE_FORMAT = DateTimeFormatter.ofPattern("dd-MM");
    private static final Pattern WHITESPACE = Pattern.compile("\\s+");

    public String sanitizeNote(String note) {
        if (note == null || note.isBlank()) {
            return null;
        }
        return WHITESPACE.matcher(note.trim()).replaceAll(" ");
    }

    public String displayText(LunchOrder order) {
        String dishes = order.getItems().stream()
                .map(item -> item.getItemNameSnapshot())
                .collect(Collectors.joining(" + "));
        String note = sanitizeNote(order.getNote());
        return note == null ? dishes : dishes + " (" + note + ")";
    }

    public String summaryText(LunchMenu menu, List<LunchOrder> orders) {
        String label = menu.getOrderLabel() == null || menu.getOrderLabel().isBlank()
                ? "Đặt cơm"
                : menu.getOrderLabel().trim();
        String header = "%s - %s: %d phần".formatted(
                label,
                menu.getMenuDate().format(ORDER_DATE_FORMAT),
                orders.size()
        );
        if (orders.isEmpty()) {
            return header;
        }
        return header + "\n" + orders.stream()
                .map(order -> "- " + displayText(order))
                .collect(Collectors.joining("\n"));
    }
}
