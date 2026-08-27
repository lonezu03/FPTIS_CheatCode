package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenuItem;
import com.fittrack.lunch.entity.LunchMenuItemType;
import com.fittrack.lunch.entity.LunchSelectionType;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class LunchOrderRulesTest {

    private final LunchOrderRules rules = new LunchOrderRules();

    @Test
    void acceptsExactlyTwoDifferentRegularItemsForCombo() {
        assertDoesNotThrow(() -> rules.validateSelection(
                LunchSelectionType.COMBO,
                List.of(regular("1"), regular("2"))
        ));
    }

    @Test
    void acceptsDuplicateRegularItemForCombo() {
        LunchMenuItem item = regular("1");

        assertDoesNotThrow(() -> rules.validateSelection(
                LunchSelectionType.COMBO,
                List.of(item, item)
        ));
    }

    @Test
    void rejectsMoreThanTwoRegularSlotsForCombo() {
        assertThrows(
                IllegalArgumentException.class,
                () -> rules.validateSelection(
                        LunchSelectionType.COMBO,
                        List.of(regular("1"), regular("2"), regular("3"))
                )
        );
    }

    @Test
    void rejectsSpecialItemInsideCombo() {
        assertThrows(
                IllegalArgumentException.class,
                () -> rules.validateSelection(
                        LunchSelectionType.COMBO,
                        List.of(regular("1"), special("2"))
                )
        );
    }

    @Test
    void acceptsExactlyOneSpecialItemForSingle() {
        assertDoesNotThrow(() -> rules.validateSelection(
                LunchSelectionType.SINGLE,
                List.of(special("1"))
        ));
    }

    @Test
    void rejectsRegularItemForSingle() {
        assertThrows(
                IllegalArgumentException.class,
                () -> rules.validateSelection(
                        LunchSelectionType.SINGLE,
                        List.of(regular("1"))
                )
        );
    }

    private LunchMenuItem regular(String id) {
        return item(id, LunchMenuItemType.REGULAR);
    }

    private LunchMenuItem special(String id) {
        return item(id, LunchMenuItemType.SPECIAL);
    }

    private LunchMenuItem item(String id, LunchMenuItemType type) {
        return LunchMenuItem.builder()
                .id(id)
                .name("Món " + id)
                .type(type)
                .sortOrder(0)
                .build();
    }
}
