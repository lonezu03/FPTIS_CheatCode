package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenuItem;
import com.fittrack.lunch.entity.LunchMenuItemType;
import com.fittrack.lunch.entity.LunchSelectionType;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class LunchOrderRules {

    public void validateSelection(
            LunchSelectionType selectionType,
            List<LunchMenuItem> selectedItems
    ) {
        if (selectionType == null) {
            throw new IllegalArgumentException("Vui lòng chọn loại phần ăn");
        }
        if (selectedItems == null) {
            throw new IllegalArgumentException("Vui lòng chọn món");
        }

        if (selectedItems.stream().anyMatch(item -> item == null || item.getId() == null)) {
            throw new IllegalArgumentException("Vui lòng chọn món hợp lệ");
        }

        if (selectionType == LunchSelectionType.COMBO) {
            if (selectedItems.size() != 2) {
                throw new IllegalArgumentException("Một phần cơm phải chọn đúng 2 món thường");
            }
            if (selectedItems.stream().anyMatch(item -> item.getType() != LunchMenuItemType.REGULAR)) {
                throw new IllegalArgumentException("Phần cơm chỉ được chọn món thường trước dấu '+'");
            }
            return;
        }

        if (selectedItems.size() != 1) {
            throw new IllegalArgumentException("Món đặc biệt chỉ được chọn đúng 1 món");
        }
        if (selectedItems.getFirst().getType() != LunchMenuItemType.SPECIAL) {
            throw new IllegalArgumentException("Phần đơn chỉ được chọn món đặc biệt sau dấu '+'");
        }
    }
}
