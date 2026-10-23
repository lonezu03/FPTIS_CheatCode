package com.fittrack.finance.service;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ReceiptAnalysisServiceTest {
    @Test
    void hidesCardAndAccountNumbersFromGeneratedText() {
        String result = ReceiptAnalysisService.redactFinancialIdentifiers("Thẻ 4111 1111 1111 1111, tài khoản 1234567890.");
        assertFalse(result.contains("4111"));
        assertFalse(result.contains("1234567890"));
        assertTrue(result.contains("[đã ẩn số tài khoản/thẻ]"));
    }

    @Test
    void keepsOrdinaryReceiptDetails() {
        assertEquals("Cà phê 35.000 đ", ReceiptAnalysisService.redactFinancialIdentifiers("Cà phê 35.000 đ"));
        assertNull(ReceiptAnalysisService.redactFinancialIdentifiers(null));
    }

    @Test
    void boundsAndRedactsEveryAiTextField() {
        String text = "Quán 1234567890123456 " + "x".repeat(200);
        String merchant = ReceiptAnalysisService.safeText(text, 120);
        assertFalse(merchant.contains("1234567890123456"));
        assertEquals(120, merchant.length());
    }
}
