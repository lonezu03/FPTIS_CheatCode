package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenu;
import com.fittrack.lunch.entity.LunchOrder;
import com.fittrack.lunch.entity.LunchOrderItem;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class LunchTextFormatterTest {

    private final LunchTextFormatter formatter = new LunchTextFormatter();

    @Test
    void createsExactVendorTextAndSanitizesMultilineNote() {
        LunchMenu menu = LunchMenu.builder()
                .menuDate(LocalDate.of(2026, 7, 21))
                .orderLabel("Vũ")
                .build();
        LunchOrder combo = order(
                "  cơm thêm \n rau thêm  ",
                "Sườn ram",
                "Canh khổ qua dồn thịt"
        );
        LunchOrder single = order(null, "Phở bò");

        String result = formatter.summaryText(menu, List.of(combo, single));

        assertEquals(
                """
                        Vũ - 21-07: 2 phần
                        - Sườn ram + Canh khổ qua dồn thịt (cơm thêm rau thêm)
                        - Phở bò""",
                result
        );
    }

    private LunchOrder order(String note, String... itemNames) {
        LunchOrder order = LunchOrder.builder()
                .note(note)
                .build();
        for (int index = 0; index < itemNames.length; index++) {
            order.getItems().add(LunchOrderItem.builder()
                    .order(order)
                    .itemNameSnapshot(itemNames[index])
                    .sortOrder(index)
                    .build());
        }
        return order;
    }
}
