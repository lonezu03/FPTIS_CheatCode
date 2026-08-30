package com.fittrack.nutrition.service;

import com.fittrack.nutrition.dto.CreateMealItemRequest;
import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.dto.MealLogResponse;
import com.fittrack.nutrition.dto.NutritionDiaryResponse;
import com.fittrack.nutrition.dto.NutritionTotalsResponse;
import com.fittrack.nutrition.dto.UpdateMealItemRequest;
import com.fittrack.nutrition.dto.UpdateMealLogRequest;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.entity.MealItem;
import com.fittrack.nutrition.entity.MealLog;
import com.fittrack.nutrition.mapper.NutritionMapper;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.MealLogRepository;
import com.fittrack.user.entity.User;
import com.fittrack.user.service.GoalCalculatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import com.fittrack.common.dto.PageResponse;

@Service
@RequiredArgsConstructor
public class NutritionService {

    private final FoodRepository foodRepository;
    private final MealLogRepository mealLogRepository;
    private final NutritionMapper nutritionMapper;
    private final NutritionDayQualityService dayQualityService;
    private final WaterLogService waterLogService;
    private final GoalCalculatorService goalCalculatorService;

    @Transactional
    public MealLogResponse createMealLog(User user, CreateMealLogRequest request) {
        MealLog mealLog = MealLog.builder()
                .user(user)
                .mealType(request.getMealType())
                .logDate(request.getLogDate())
                .totalCalories(0.0)
                .totalProtein(0.0)
                .totalCarbs(0.0)
                .totalFat(0.0)
                .build();

        if (request.getItems() != null) {
            for (CreateMealItemRequest itemRequest : request.getItems()) {
                Food food = findActiveFood(itemRequest.getFoodId());

                ItemAmount amount = itemAmount(
                        food,
                        itemRequest.getQuantity(),
                        itemRequest.getServingAmount(),
                        itemRequest.getServingUnit()
                );
                double quantity = amount.factor();

                double calories = defaultZero(food.getCalories()) * quantity;
                double protein = defaultZero(food.getProtein()) * quantity;
                double carbs = defaultZero(food.getCarbs()) * quantity;
                double fat = defaultZero(food.getFat()) * quantity;

                MealItem item = MealItem.builder()
                        .mealLog(mealLog)
                        .food(food)
                        .quantity(quantity)
                        .servingAmount(amount.amount())
                        .servingUnit(amount.unit())
                        .gramsEquivalent(amount.gramsEquivalent())
                        .calories(calories)
                        .protein(protein)
                        .carbs(carbs)
                        .fat(fat)
                        .fiber(scaleNullable(food.getFiber(), quantity))
                        .sugar(scaleNullable(food.getSugar(), quantity))
                        .sodium(scaleNullable(food.getSodium(), quantity))
                        .potassium(scaleNullable(food.getPotassium(), quantity))
                        .calcium(scaleNullable(food.getCalcium(), quantity))
                        .iron(scaleNullable(food.getIron(), quantity))
                        .vitaminC(scaleNullable(food.getVitaminC(), quantity))
                        .water(scaleNullable(food.getWater(), quantity))
                        .build();

                mealLog.getItems().add(item);

                mealLog.setTotalCalories(mealLog.getTotalCalories() + calories);
                mealLog.setTotalProtein(mealLog.getTotalProtein() + protein);
                mealLog.setTotalCarbs(mealLog.getTotalCarbs() + carbs);
                mealLog.setTotalFat(mealLog.getTotalFat() + fat);
            }
        }

        MealLog savedMealLog = mealLogRepository.save(mealLog);
        dayQualityService.markPartial(user, savedMealLog.getLogDate(), true);

        return nutritionMapper.toMealLogResponse(savedMealLog);
    }

    @Transactional(readOnly = true)
    public List<MealLogResponse> getMyMealLogsByDate(User user, LocalDate date) {
        return nutritionMapper.toMealLogResponseList(
                mealLogRepository.findByUserAndLogDateOrderByCreatedAtDesc(user, date)
        );
    }

    @Transactional(readOnly = true)
    public List<MealLogResponse> getMyMealLogs(User user) {
        return nutritionMapper.toMealLogResponseList(
                mealLogRepository.findByUserOrderByLogDateDesc(user)
        );
    }

    @Transactional
    public void deleteMealLog(User user, String mealLogId) {
        MealLog mealLog = mealLogRepository.findByIdAndUser(mealLogId, user)
                .orElseThrow(() -> new IllegalArgumentException("Meal log not found"));
        ensureManual(mealLog);

        LocalDate date = mealLog.getLogDate();
        mealLogRepository.delete(mealLog);
        mealLogRepository.flush();
        dayQualityService.markPartial(
                user,
                date,
                !mealLogRepository.findByUserAndLogDate(user, date).isEmpty()
        );
    }

    @Transactional
    public MealLogResponse updateMealLog(
            User user,
            String mealLogId,
            UpdateMealLogRequest request
    ) {
        MealLog mealLog = mealLogRepository.findByIdAndUser(mealLogId, user)
                .orElseThrow(() -> new IllegalArgumentException("Meal log not found"));
        ensureManual(mealLog);
        LocalDate previousDate = mealLog.getLogDate();

        mealLog.setMealType(request.getMealType());
        mealLog.setLogDate(request.getLogDate());

        mealLog.getItems().clear();

        mealLog.setTotalCalories(0.0);
        mealLog.setTotalProtein(0.0);
        mealLog.setTotalCarbs(0.0);
        mealLog.setTotalFat(0.0);

        if (request.getItems() != null) {
            for (UpdateMealItemRequest itemRequest : request.getItems()) {
                Food food = findActiveFood(itemRequest.getFoodId());

                ItemAmount amount = itemAmount(
                        food,
                        itemRequest.getQuantity(),
                        itemRequest.getServingAmount(),
                        itemRequest.getServingUnit()
                );
                double quantity = amount.factor();

                double calories = defaultZero(food.getCalories()) * quantity;
                double protein = defaultZero(food.getProtein()) * quantity;
                double carbs = defaultZero(food.getCarbs()) * quantity;
                double fat = defaultZero(food.getFat()) * quantity;

                MealItem item = MealItem.builder()
                        .mealLog(mealLog)
                        .food(food)
                        .quantity(quantity)
                        .servingAmount(amount.amount())
                        .servingUnit(amount.unit())
                        .gramsEquivalent(amount.gramsEquivalent())
                        .calories(calories)
                        .protein(protein)
                        .carbs(carbs)
                        .fat(fat)
                        .fiber(scaleNullable(food.getFiber(), quantity))
                        .sugar(scaleNullable(food.getSugar(), quantity))
                        .sodium(scaleNullable(food.getSodium(), quantity))
                        .potassium(scaleNullable(food.getPotassium(), quantity))
                        .calcium(scaleNullable(food.getCalcium(), quantity))
                        .iron(scaleNullable(food.getIron(), quantity))
                        .vitaminC(scaleNullable(food.getVitaminC(), quantity))
                        .water(scaleNullable(food.getWater(), quantity))
                        .build();

                mealLog.getItems().add(item);

                mealLog.setTotalCalories(mealLog.getTotalCalories() + calories);
                mealLog.setTotalProtein(mealLog.getTotalProtein() + protein);
                mealLog.setTotalCarbs(mealLog.getTotalCarbs() + carbs);
                mealLog.setTotalFat(mealLog.getTotalFat() + fat);
            }
        }

        MealLog saved = mealLogRepository.save(mealLog);
        dayQualityService.markPartial(user, saved.getLogDate(), true);
        if (!previousDate.equals(saved.getLogDate())) {
            dayQualityService.markPartial(
                    user,
                    previousDate,
                    !mealLogRepository.findByUserAndLogDate(user, previousDate).isEmpty()
            );
        }

        return nutritionMapper.toMealLogResponse(saved);
    }

    private Food findActiveFood(String foodId) {
        Food food = foodRepository.findById(foodId)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        if (Boolean.FALSE.equals(food.getActive())) {
            throw new IllegalArgumentException("Food is inactive");
        }

        return food;
    }

    private double defaultZero(Double value) {
        return value == null ? 0.0 : value;
    }

    private Double scaleNullable(Double value, double factor) {
        return value == null ? null : value * factor;
    }

    private ItemAmount itemAmount(
            Food food,
            Double legacyQuantity,
            Double servingAmount,
            String requestedUnit
    ) {
        double amount = servingAmount == null
                ? (legacyQuantity == null ? 1.0 : legacyQuantity)
                : servingAmount;
        if (amount <= 0) {
            throw new IllegalArgumentException("Số lượng thực phẩm phải lớn hơn 0");
        }
        String unit = requestedUnit == null || requestedUnit.isBlank()
                ? "SERVING"
                : requestedUnit.trim().toUpperCase();
        if (!java.util.Set.of("SERVING", "GRAM", "ML").contains(unit)) {
            throw new IllegalArgumentException("Đơn vị thực phẩm không hợp lệ");
        }
        if ("SERVING".equals(unit)) {
            Double grams = food.getServingSizeGrams() == null
                    ? null
                    : amount * food.getServingSizeGrams();
            return new ItemAmount(amount, unit, amount, grams);
        }
        if (food.getServingSizeGrams() == null || food.getServingSizeGrams() <= 0) {
            throw new IllegalArgumentException(
                    "Thực phẩm này chưa có quy đổi gram/ml. Hãy dùng khẩu phần"
            );
        }
        return new ItemAmount(
                amount / food.getServingSizeGrams(),
                unit,
                amount,
                amount
        );
    }

    @Transactional(readOnly = true)
    public NutritionDiaryResponse getDiary(User user, LocalDate requestedDate) {
        LocalDate date = requestedDate == null ? LocalDate.now() : requestedDate;
        List<MealLog> meals = mealLogRepository.findByUserAndLogDateOrderByCreatedAtDesc(user, date);
        double calories = meals.stream().mapToDouble(item -> defaultZero(item.getTotalCalories())).sum();
        double protein = meals.stream().mapToDouble(item -> defaultZero(item.getTotalProtein())).sum();
        double carbs = meals.stream().mapToDouble(item -> defaultZero(item.getTotalCarbs())).sum();
        double fat = meals.stream().mapToDouble(item -> defaultZero(item.getTotalFat())).sum();
        double targetCalories = goalCalculatorService.calculateTargetCalories(user);
        double targetProtein = goalCalculatorService.calculateProtein(user);
        double targetCarbs = goalCalculatorService.calculateCarbs(user);
        double targetFat = goalCalculatorService.calculateFat(user);
        return NutritionDiaryResponse.builder()
                .date(date)
                .status(dayQualityService.resolve(user, date, meals))
                .statusExplicit(dayQualityService.isExplicit(user, date))
                .consumed(totals(calories, protein, carbs, fat))
                .targets(totals(targetCalories, targetProtein, targetCarbs, targetFat))
                .remaining(totals(
                        targetCalories - calories,
                        targetProtein - protein,
                        targetCarbs - carbs,
                        targetFat - fat
                ))
                .waterMl(waterLogService.totalByDate(user, date))
                .waterTargetMl(waterTarget(user))
                .meals(nutritionMapper.toMealLogResponseList(meals))
                .build();
    }

    @Transactional
    public com.fittrack.nutrition.entity.NutritionDayStatus updateDayStatus(
            User user,
            LocalDate date,
            com.fittrack.nutrition.entity.NutritionDayStatus status
    ) {
        boolean hasMeals = !mealLogRepository.findByUserAndLogDate(user, date).isEmpty();
        return dayQualityService.update(user, date, status, hasMeals);
    }

    private NutritionTotalsResponse totals(double calories, double protein, double carbs, double fat) {
        return NutritionTotalsResponse.builder()
                .calories(round(calories))
                .protein(round(protein))
                .carbs(round(carbs))
                .fat(round(fat))
                .build();
    }

    private int waterTarget(User user) {
        double weight = user.getWeight() == null || user.getWeight() <= 0 ? 60 : user.getWeight();
        return (int) Math.round(Math.max(1500, Math.min(4000, weight * 35)));
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private record ItemAmount(
            double factor,
            String unit,
            double amount,
            Double gramsEquivalent
    ) {
    }

    @Transactional(readOnly = true)
    public PageResponse<MealLogResponse> getMyMealLogsPage(
            User user,
            LocalDate date,
            int page,
            int size
    ) {
        PageRequest pageable = PageRequest.of(
                Math.max(page, 0), Math.min(Math.max(size, 1), 100)
        );
        var result = (date == null
                ? mealLogRepository.findByUserOrderByLogDateDescCreatedAtDesc(user, pageable)
                : mealLogRepository.findByUserAndLogDateOrderByCreatedAtDesc(user, date, pageable))
                .map(nutritionMapper::toMealLogResponse);
        return PageResponse.from(result);
    }

    private void ensureManual(MealLog mealLog) {
        if (mealLog.getSourceLunchOrderId() != null) {
            throw new IllegalArgumentException(
                    "Bữa ăn từ đơn cơm được cập nhật tự động. Hãy sửa hoặc hủy tại trang Đặt cơm"
            );
        }
    }
}

