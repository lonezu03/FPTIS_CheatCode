package com.fittrack.nutrition.service;

import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.entity.NutritionDayState;
import com.fittrack.nutrition.entity.NutritionDayStatus;
import com.fittrack.nutrition.repository.NutritionDayStateRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NutritionDayQualityService {

    private final NutritionDayStateRepository repository;

    @Transactional(readOnly = true)
    public NutritionDayStatus resolve(User user, LocalDate date, List<MealLog> meals) {
        return repository.findByUserAndLogDate(user, date)
                .map(NutritionDayState::getStatus)
                .orElse(meals.isEmpty() ? NutritionDayStatus.UNLOGGED : NutritionDayStatus.PARTIAL);
    }

    @Transactional(readOnly = true)
    public boolean isExplicit(User user, LocalDate date) {
        return repository.findByUserAndLogDate(user, date).isPresent();
    }

    @Transactional
    public NutritionDayStatus update(
            User user,
            LocalDate date,
            NutritionDayStatus status,
            boolean hasMeals
    ) {
        if (status == NutritionDayStatus.FASTING && hasMeals) {
            throw new IllegalArgumentException("Ngày nhịn ăn không được có bữa ăn đã ghi");
        }
        if (status == NutritionDayStatus.COMPLETE && !hasMeals) {
            throw new IllegalArgumentException("Hãy ghi bữa ăn hoặc chọn trạng thái nhịn ăn");
        }
        NutritionDayState state = repository.findByUserAndLogDate(user, date)
                .orElseGet(() -> NutritionDayState.builder()
                        .user(user)
                        .logDate(date)
                        .build());
        state.setStatus(status);
        return repository.save(state).getStatus();
    }

    @Transactional
    public void markPartial(User user, LocalDate date, boolean hasMeals) {
        NutritionDayState state = repository.findByUserAndLogDate(user, date)
                .orElseGet(() -> NutritionDayState.builder()
                        .user(user)
                        .logDate(date)
                        .build());
        state.setStatus(hasMeals ? NutritionDayStatus.PARTIAL : NutritionDayStatus.UNLOGGED);
        repository.save(state);
    }

    @Transactional(readOnly = true)
    public Map<LocalDate, NutritionDayStatus> statuses(
            User user,
            LocalDate from,
            LocalDate to
    ) {
        return repository.findByUserAndLogDateBetween(user, from, to).stream()
                .collect(Collectors.toMap(
                        NutritionDayState::getLogDate,
                        NutritionDayState::getStatus,
                        (left, right) -> right
                ));
    }

    public NutritionDayStatus resolve(
            LocalDate date,
            Map<LocalDate, NutritionDayStatus> explicit,
            Map<LocalDate, List<MealLog>> mealsByDate
    ) {
        return explicit.getOrDefault(
                date,
                mealsByDate.getOrDefault(date, List.of()).isEmpty()
                        ? NutritionDayStatus.UNLOGGED
                        : NutritionDayStatus.PARTIAL
        );
    }

    public boolean isComplete(NutritionDayStatus status) {
        return status == NutritionDayStatus.COMPLETE || status == NutritionDayStatus.FASTING;
    }
}
