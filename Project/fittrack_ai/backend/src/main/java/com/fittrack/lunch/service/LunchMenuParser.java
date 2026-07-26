package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenuItemType;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.regex.Pattern;

@Component
public class LunchMenuParser {

    private static final Pattern WHITESPACE = Pattern.compile("\\s+");

    public ParsedMenu parse(String rawMenuText) {
        if (rawMenuText == null || rawMenuText.isBlank()) {
            throw new IllegalArgumentException("Nội dung thực đơn không được để trống");
        }

        List<ParsedItem> regularItems = new ArrayList<>();
        List<ParsedItem> specialItems = new ArrayList<>();
        Set<String> normalizedNames = new HashSet<>();
        boolean afterSeparator = false;
        boolean sawSeparator = false;
        int sortOrder = 0;

        for (String rawLine : rawMenuText.split("\\R")) {
            String line = normalizeVisibleWhitespace(rawLine);
            if (line.isBlank()) {
                continue;
            }

            if ("+".equals(line)) {
                if (sawSeparator) {
                    throw new IllegalArgumentException("Thực đơn chỉ được có một dòng phân cách '+'");
                }
                sawSeparator = true;
                afterSeparator = true;
                continue;
            }

            if (line.length() > 255) {
                throw new IllegalArgumentException("Tên món không được dài quá 255 ký tự");
            }
            String normalizedName = line.toLowerCase(Locale.ROOT);
            if (!normalizedNames.add(normalizedName)) {
                throw new IllegalArgumentException("Món ăn bị trùng: " + line);
            }

            LunchMenuItemType type = afterSeparator
                    ? LunchMenuItemType.SPECIAL
                    : LunchMenuItemType.REGULAR;
            ParsedItem item = new ParsedItem(line, type, sortOrder++);
            if (type == LunchMenuItemType.REGULAR) {
                regularItems.add(item);
            } else {
                specialItems.add(item);
            }
        }

        if (regularItems.isEmpty() && specialItems.isEmpty()) {
            throw new IllegalArgumentException("Thực đơn không có món ăn");
        }
        if (regularItems.size() == 1) {
            throw new IllegalArgumentException("Nhóm món thường phải có ít nhất 2 món để tạo một phần");
        }
        if (sawSeparator && specialItems.isEmpty()) {
            throw new IllegalArgumentException("Phải có ít nhất một món đặc biệt sau dòng '+'");
        }

        return new ParsedMenu(List.copyOf(regularItems), List.copyOf(specialItems));
    }

    private String normalizeVisibleWhitespace(String value) {
        return WHITESPACE.matcher(value == null ? "" : value.trim()).replaceAll(" ");
    }

    public record ParsedMenu(
            List<ParsedItem> regularItems,
            List<ParsedItem> specialItems
    ) {
        public List<ParsedItem> allItems() {
            List<ParsedItem> all = new ArrayList<>(regularItems.size() + specialItems.size());
            all.addAll(regularItems);
            all.addAll(specialItems);
            return all;
        }
    }

    public record ParsedItem(
            String name,
            LunchMenuItemType type,
            int sortOrder
    ) {
    }
}
