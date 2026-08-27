package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenuItemType;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class LunchMenuParser {

    private static final Pattern WHITESPACE = Pattern.compile("\\s+");
    private static final Pattern TRAILING_PRICE = Pattern.compile("^(.+?)(?:\\s*[|:]\\s*|\\s+)(\\d{1,9})$");

    public ParsedMenu parse(String rawMenuText) {
        if (rawMenuText == null || rawMenuText.isBlank()) {
            throw new IllegalArgumentException("Nội dung thực đơn không được để trống");
        }

        List<ParsedItem> regularItems = new ArrayList<>();
        List<ParsedItem> specialItems = new ArrayList<>();
        List<ParsedItem> extraItems = new ArrayList<>();
        Set<String> normalizedNames = new HashSet<>();
        LunchMenuItemType currentType = LunchMenuItemType.REGULAR;
        boolean sawSeparator = false;
        int sortOrder = 0;

        for (String rawLine : rawMenuText.split("\\R")) {
            String line = normalizeVisibleWhitespace(rawLine);
            if (line.isBlank()) {
                continue;
            }

            String marker = line.toUpperCase(Locale.ROOT);
            if (marker.equals("@DRINKS") || marker.equals("@EXTRAS")) {
                currentType = LunchMenuItemType.EXTRA;
                continue;
            }
            if ("+".equals(line)) {
                if (sawSeparator || currentType == LunchMenuItemType.EXTRA) {
                    throw new IllegalArgumentException("Thực đơn chỉ được có một dòng phân cách '+' trước nhóm món thêm");
                }
                sawSeparator = true;
                currentType = LunchMenuItemType.SPECIAL;
                continue;
            }

            ParsedName parsedName = parseNameAndPrice(line, currentType);
            if (parsedName.name().length() > 255) {
                throw new IllegalArgumentException("Tên món không được dài quá 255 ký tự");
            }
            String normalizedName = parsedName.name().toLowerCase(Locale.ROOT);
            if (!normalizedNames.add(normalizedName)) {
                throw new IllegalArgumentException("Món ăn bị trùng: " + parsedName.name());
            }
            if (currentType == LunchMenuItemType.EXTRA && parsedName.unitPrice() == null) {
                throw new IllegalArgumentException("Món thêm phải có giá, ví dụ: Trà đào | 45000");
            }

            ParsedItem item = new ParsedItem(
                    parsedName.name(),
                    currentType,
                    sortOrder++,
                    parsedName.unitPrice()
            );
            switch (currentType) {
                case REGULAR -> regularItems.add(item);
                case SPECIAL -> specialItems.add(item);
                case EXTRA -> extraItems.add(item);
            }
        }

        if (regularItems.isEmpty() && specialItems.isEmpty()) {
            throw new IllegalArgumentException("Thực đơn phải có ít nhất một món cơm hoặc món đơn");
        }
        if (regularItems.size() == 1) {
            throw new IllegalArgumentException("Nhóm món thường phải có ít nhất 2 món để tạo một phần");
        }
        if (sawSeparator && specialItems.isEmpty()) {
            throw new IllegalArgumentException("Phải có ít nhất một món đặc biệt sau dòng '+'");
        }

        return new ParsedMenu(
                List.copyOf(regularItems),
                List.copyOf(specialItems),
                List.copyOf(extraItems)
        );
    }

    private ParsedName parseNameAndPrice(String line, LunchMenuItemType type) {
        if (type != LunchMenuItemType.EXTRA) {
            return new ParsedName(line, null);
        }
        Matcher matcher = TRAILING_PRICE.matcher(line);
        if (!matcher.matches()) {
            return new ParsedName(line, null);
        }
        long price;
        try {
            price = Long.parseLong(matcher.group(2));
        } catch (NumberFormatException exception) {
            throw new IllegalArgumentException("Giá món thêm không hợp lệ: " + line);
        }
        if (price <= 0) {
            throw new IllegalArgumentException("Giá món thêm phải lớn hơn 0: " + line);
        }
        return new ParsedName(normalizeVisibleWhitespace(matcher.group(1)), price);
    }

    private String normalizeVisibleWhitespace(String value) {
        return WHITESPACE.matcher(value == null ? "" : value.trim()).replaceAll(" ");
    }

    private record ParsedName(String name, Long unitPrice) {
    }

    public record ParsedMenu(
            List<ParsedItem> regularItems,
            List<ParsedItem> specialItems,
            List<ParsedItem> extraItems
    ) {
        public List<ParsedItem> allItems() {
            List<ParsedItem> all = new ArrayList<>(regularItems.size() + specialItems.size() + extraItems.size());
            all.addAll(regularItems);
            all.addAll(specialItems);
            all.addAll(extraItems);
            return all;
        }
    }

    public record ParsedItem(
            String name,
            LunchMenuItemType type,
            int sortOrder,
            Long unitPrice
    ) {
    }
}
