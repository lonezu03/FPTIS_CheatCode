package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchPaymentSettings;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LunchPaymentSettingsRepository extends JpaRepository<LunchPaymentSettings, String> {
}
