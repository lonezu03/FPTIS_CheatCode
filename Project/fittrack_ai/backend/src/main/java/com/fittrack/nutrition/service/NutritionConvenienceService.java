package com.fittrack.nutrition.service;

import com.fittrack.nutrition.dto.CreateMealItemRequest;
import com.fittrack.nutrition.dto.CreateMealLogRequest;
import com.fittrack.nutrition.dto.MealLogResponse;
import com.fittrack.nutrition.dto.NutritionConvenienceDtos.*;
import com.fittrack.nutrition.entity.*;
import com.fittrack.nutrition.mapper.NutritionMapper;
import com.fittrack.nutrition.repository.FoodPreferenceRepository;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.nutrition.repository.NutritionCollectionRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class NutritionConvenienceService {
    private static final Set<String> UNITS = Set.of("SERVING", "GRAM", "ML");
    private static final Set<String> MEAL_TYPES = Set.of("BREAKFAST", "LUNCH", "DINNER", "SNACK");

    private final FoodPreferenceRepository preferenceRepository;
    private final NutritionCollectionRepository collectionRepository;
    private final FoodRepository foodRepository;
    private final NutritionMapper nutritionMapper;
    private final NutritionService nutritionService;

    @Transactional(readOnly = true)
    public ConvenienceResponse overview(User user) {
        List<FoodShortcutResponse> recent = preferenceRepository
                .findByUserAndLastUsedAtIsNotNullOrderByLastUsedAtDesc(
                        user, PageRequest.of(0, 12)
                ).stream().filter(this::eligible).map(this::shortcut).toList();
        List<FoodShortcutResponse> favorites = preferenceRepository
                .findByUserAndFavoriteTrueOrderByUpdatedAtDesc(user).stream()
                .filter(this::eligible).map(this::shortcut).toList();
        List<CollectionResponse> collections = collectionRepository
                .findByUserAndActiveTrueOrderByUpdatedAtDesc(user).stream()
                .map(this::response).toList();
        return new ConvenienceResponse(
                recent,
                favorites,
                collections.stream().filter(value -> value.type() == NutritionCollectionType.SAVED_MEAL).toList(),
                collections.stream().filter(value -> value.type() == NutritionCollectionType.RECIPE).toList()
        );
    }

    @Transactional
    public FoodShortcutResponse setFavorite(User user, String foodId, boolean favorite) {
        Food food = requireFood(foodId);
        FoodPreference preference = preferenceRepository.findByUserAndFoodId(user, foodId)
                .orElseGet(() -> FoodPreference.builder().user(user).food(food).build());
        preference.setFavorite(favorite);
        return shortcut(preferenceRepository.save(preference));
    }

    @Transactional
    public CollectionResponse create(User user, CollectionRequest request) {
        NutritionCollection collection = NutritionCollection.builder()
                .user(user)
                .active(true)
                .build();
        apply(collection, request);
        return response(collectionRepository.save(collection));
    }

    @Transactional
    public CollectionResponse update(User user, String id, CollectionRequest request) {
        NutritionCollection collection = collectionRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy bữa ăn đã lưu"));
        apply(collection, request);
        return response(collectionRepository.save(collection));
    }

    @Transactional
    public void delete(User user, String id) {
        NutritionCollection collection = collectionRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy bữa ăn đã lưu"));
        collection.setActive(false);
        collectionRepository.save(collection);
    }

    @Transactional
    public MealLogResponse log(User user, String id, LogCollectionRequest request) {
        NutritionCollection collection = collectionRepository.findByIdAndUser(id, user)
                .filter(value -> Boolean.TRUE.equals(value.getActive()))
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy bữa ăn đã lưu"));
        String mealType = request.mealType().trim().toUpperCase();
        if (!MEAL_TYPES.contains(mealType)) {
            throw new IllegalArgumentException("Loại bữa ăn không hợp lệ");
        }
        double multiplier = request.servings() / collection.getServings();
        CreateMealLogRequest meal = new CreateMealLogRequest();
        meal.setLogDate(request.logDate());
        meal.setMealType(mealType);
        List<CreateMealItemRequest> items = new ArrayList<>();
        for (NutritionCollectionItem source : collection.getItems()) {
            CreateMealItemRequest item = new CreateMealItemRequest();
            item.setFoodId(source.getFood().getId());
            item.setServingAmount(source.getServingAmount() * multiplier);
            item.setServingUnit(source.getServingUnit());
            items.add(item);
        }
        meal.setItems(items);
        return nutritionService.createMealLog(user, meal);
    }

    private void apply(NutritionCollection collection, CollectionRequest request) {
        collection.setName(request.name().trim());
        collection.setDescription(blankToNull(request.description()));
        collection.setType(request.type());
        collection.setServings(request.servings());
        collection.setUpdatedAt(LocalDateTime.now());
        collection.getItems().clear();
        int order = 1;
        for (CollectionItemRequest value : request.items()) {
            Food food = requireFood(value.foodId());
            String unit = value.servingUnit().trim().toUpperCase();
            if (!UNITS.contains(unit)) {
                throw new IllegalArgumentException("Đơn vị thực phẩm không hợp lệ");
            }
            if (!"SERVING".equals(unit)
                    && (food.getServingSizeGrams() == null || food.getServingSizeGrams() <= 0)) {
                throw new IllegalArgumentException(
                        "Món " + food.getName() + " chưa có quy đổi gram/ml"
                );
            }
            collection.getItems().add(NutritionCollectionItem.builder()
                    .collection(collection)
                    .food(food)
                    .servingAmount(value.servingAmount())
                    .servingUnit(unit)
                    .itemOrder(order++)
                    .build());
        }
    }

    private CollectionResponse response(NutritionCollection collection) {
        List<CollectionItemResponse> items = collection.getItems().stream()
                .map(item -> {
                    double factor = factor(item.getFood(), item.getServingAmount(), item.getServingUnit());
                    return new CollectionItemResponse(
                            item.getFood().getId(),
                            item.getFood().getName(),
                            item.getServingAmount(),
                            item.getServingUnit(),
                            round(value(item.getFood().getCalories()) * factor),
                            round(value(item.getFood().getProtein()) * factor),
                            round(value(item.getFood().getCarbs()) * factor),
                            round(value(item.getFood().getFat()) * factor)
                    );
                }).toList();
        double servings = collection.getServings() == null || collection.getServings() <= 0
                ? 1 : collection.getServings();
        return new CollectionResponse(
                collection.getId(), collection.getName(), collection.getDescription(),
                collection.getType(), servings,
                round(items.stream().mapToDouble(CollectionItemResponse::calories).sum() / servings),
                round(items.stream().mapToDouble(CollectionItemResponse::protein).sum() / servings),
                round(items.stream().mapToDouble(CollectionItemResponse::carbs).sum() / servings),
                round(items.stream().mapToDouble(CollectionItemResponse::fat).sum() / servings),
                items, collection.getUpdatedAt()
        );
    }

    private FoodShortcutResponse shortcut(FoodPreference preference) {
        return new FoodShortcutResponse(
                nutritionMapper.toFoodResponse(preference.getFood()),
                Boolean.TRUE.equals(preference.getFavorite()),
                preference.getUseCount() == null ? 0 : preference.getUseCount(),
                preference.getLastUsedAt()
        );
    }

    private boolean eligible(FoodPreference preference) {
        Food food = preference.getFood();
        return Boolean.TRUE.equals(food.getActive()) && "APPROVED".equals(food.getApprovalStatus());
    }

    private Food requireFood(String id) {
        return foodRepository.findById(id)
                .filter(food -> Boolean.TRUE.equals(food.getActive()))
                .filter(food -> "APPROVED".equals(food.getApprovalStatus()))
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy thực phẩm khả dụng"));
    }

    private double factor(Food food, double amount, String unit) {
        if ("SERVING".equals(unit)) return amount;
        return amount / food.getServingSizeGrams();
    }

    private double value(Double value) {
        return value == null ? 0 : value;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
