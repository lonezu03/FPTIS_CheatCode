package com.fittrack.lunch.service;

import com.fittrack.lunch.entity.LunchMenuItemType;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class LunchMenuParserTest {

    private final LunchMenuParser parser = new LunchMenuParser();

    @Test
    void parsesRegularItemsBeforeDelimiterAndSpecialItemsAfterDelimiter() {
        String rawMenu = """
                Lòng gà roty
                Tôm ram
                Khô cá lưỡi trâu chiên
                Sườn ram
                Cà tím nướng mỡ hành
                Thịt kho
                Trứng kho
                Gà kho sả
                Cá ngừ kho
                +
                Phở bò
                """;

        LunchMenuParser.ParsedMenu result = parser.parse(rawMenu);

        assertEquals(9, result.regularItems().size());
        assertEquals(1, result.specialItems().size());
        assertEquals("Lòng gà roty", result.regularItems().getFirst().name());
        assertEquals(LunchMenuItemType.REGULAR, result.regularItems().getFirst().type());
        assertEquals("Phở bò", result.specialItems().getFirst().name());
        assertEquals(LunchMenuItemType.SPECIAL, result.specialItems().getFirst().type());
        assertEquals(9, result.specialItems().getFirst().sortOrder());
    }

    @Test
    void onlyTreatsAStandalonePlusLineAsDelimiter() {
        LunchMenuParser.ParsedMenu result = parser.parse("""
                Cá + trứng
                Thịt kho
                """);

        assertEquals(2, result.regularItems().size());
        assertTrue(result.specialItems().isEmpty());
        assertEquals("Cá + trứng", result.regularItems().getFirst().name());
    }

    @Test
    void rejectsDuplicateDishNamesIgnoringCaseAndWhitespace() {
        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> parser.parse("""
                        Sườn   ram
                        sườn ram
                        """)
        );

        assertTrue(exception.getMessage().contains("bị trùng"));
    }

    @Test
    void rejectsMultipleDelimiters() {
        assertThrows(
                IllegalArgumentException.class,
                () -> parser.parse("""
                        Sườn ram
                        Thịt kho
                        +
                        Phở bò
                        +
                        Bún bò
                        """)
        );
    }

    @Test
    void rejectsARegularGroupThatCannotFormACombo() {
        assertThrows(
                IllegalArgumentException.class,
                () -> parser.parse("""
                        Sườn ram
                        +
                        Phở bò
                        """)
        );
    }
}
