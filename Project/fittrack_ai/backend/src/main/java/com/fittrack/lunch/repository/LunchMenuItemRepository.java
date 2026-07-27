package com.fittrack.lunch.repository;

import com.fittrack.lunch.entity.LunchMenuItem;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LunchMenuItemRepository extends JpaRepository<LunchMenuItem, String> {
}
