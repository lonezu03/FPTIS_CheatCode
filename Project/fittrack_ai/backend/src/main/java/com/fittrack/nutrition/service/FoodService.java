package com.fittrack.nutrition.service;

import com.fittrack.nutrition.dto.CreateFoodRequest;
import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.UpdateFoodRequest;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.mapper.NutritionMapper;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.common.media.ImageReferences;
import com.fittrack.common.media.MediaStorageService;
import com.fittrack.common.dto.CatalogReviewRequest;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.data.domain.PageRequest;
import com.fittrack.common.dto.PageResponse;

import java.util.List;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FoodService {

    private final FoodRepository foodRepository;
    private final NutritionMapper nutritionMapper;
    private final LunchNotificationService notificationService;
    private final MediaStorageService mediaStorageService;

    public List<FoodResponse> getFoods(String keyword, Boolean includeInactive) {
        boolean showInactive = Boolean.TRUE.equals(includeInactive);

        List<Food> foods;

        if (showInactive) {
            if (keyword == null || keyword.isBlank()) {
                foods = foodRepository.findAllByOrderByNameAsc();
            } else {
                foods = foodRepository.findByNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        } else {
            if (keyword == null || keyword.isBlank()) {
                foods = foodRepository.findByActiveTrueOrderByNameAsc();
            } else {
                foods = foodRepository.findByActiveTrueAndNameContainingIgnoreCaseOrderByNameAsc(keyword);
            }
        }

        return nutritionMapper.toFoodResponseList(foods);
    }

    public FoodResponse create(CreateFoodRequest request) {
        Food food = Food.builder()
                .name(request.getName())
                .calories(defaultZero(request.getCalories()))
                .protein(defaultZero(request.getProtein()))
                .carbs(defaultZero(request.getCarbs()))
                .fat(defaultZero(request.getFat()))
                .fiber(request.getFiber())
                .sugar(request.getSugar())
                .sodium(request.getSodium())
                .potassium(request.getPotassium())
                .calcium(request.getCalcium())
                .iron(request.getIron())
                .vitaminC(request.getVitaminC())
                .water(request.getWater())
                .unit(request.getUnit())
                .servingSizeGrams(request.getServingSizeGrams())
                .dataSourceType(sourceType(request.getDataSourceType()))
                .dataSourceName(request.getDataSourceName())
                .verified(Boolean.TRUE.equals(request.getVerified()))
                .imageUrl(mediaStorageService.storeNew(
                        request.getImageUrl(), "foods", UUID.randomUUID().toString()
                ))
                .custom(true)
                .active(true)
                .approvalStatus("APPROVED")
                .build();

        Food saved = foodRepository.save(food);

        return nutritionMapper.toFoodResponse(saved);
    }

    public PageResponse<FoodResponse> getFoodsPage(
            String keyword,
            boolean includeInactive,
            int page,
            int size
    ) {
        var result = foodRepository.searchPage(
                keyword == null ? "" : keyword.trim(),
                includeInactive,
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100))
        ).map(nutritionMapper::toFoodResponse);
        return PageResponse.from(result);
    }

    public FoodResponse createSuggestion(
            User user,
            CreateFoodRequest request
    ) {
        Food food = Food.builder()
                .name(request.getName().trim())
                .calories(defaultZero(request.getCalories()))
                .protein(defaultZero(request.getProtein()))
                .carbs(defaultZero(request.getCarbs()))
                .fat(defaultZero(request.getFat()))
                .fiber(request.getFiber())
                .sugar(request.getSugar())
                .sodium(request.getSodium())
                .potassium(request.getPotassium())
                .calcium(request.getCalcium())
                .iron(request.getIron())
                .vitaminC(request.getVitaminC())
                .water(request.getWater())
                .unit(request.getUnit())
                .servingSizeGrams(request.getServingSizeGrams())
                .dataSourceType(sourceType(request.getDataSourceType()))
                .dataSourceName(request.getDataSourceName())
                .verified(false)
                .imageUrl(mediaStorageService.storeNew(
                        request.getImageUrl(), "foods", UUID.randomUUID().toString()
                ))
                .custom(true)
                .active(false)
                .approvalStatus("PENDING")
                .submittedBy(user)
                .build();
        Food saved = foodRepository.save(food);
        notificationService.notifyAdmins(
                "CATALOG_SUBMISSION",
                "Có món ăn mới chờ duyệt",
                user.getFullName() + " đã gửi món " + saved.getName(),
                "FOOD",
                saved.getId()
        );
        return nutritionMapper.toFoodResponse(saved);
    }

    public List<FoodResponse> getMySubmissions(User user) {
        return nutritionMapper.toFoodResponseList(
                foodRepository.findBySubmittedByOrderByCreatedAtDesc(user)
        );
    }

    public FoodResponse review(
            String id,
            CatalogReviewRequest request
    ) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Không tìm thấy món ăn"
                ));
        if (!"PENDING".equals(food.getApprovalStatus())) {
            throw new IllegalArgumentException(
                    "Món ăn này đã được xử lý trước đó"
            );
        }
        food.setApprovalStatus(request.status());
        food.setAdminNote(
                request.note() == null ? null : request.note().trim()
        );
        food.setReviewedAt(LocalDateTime.now());
        food.setActive("APPROVED".equals(request.status()));
        Food saved = foodRepository.save(food);
        if (saved.getSubmittedBy() != null) {
            notificationService.notifyUser(
                    saved.getSubmittedBy(),
                    "CATALOG_REVIEW",
                    "Kết quả duyệt món ăn",
                    "Món " + saved.getName() + " đã "
                            + ("APPROVED".equals(request.status())
                            ? "được duyệt"
                            : "bị từ chối"),
                    "FOOD",
                    saved.getId()
            );
        }
        return nutritionMapper.toFoodResponse(saved);
    }

    public FoodResponse update(String id, UpdateFoodRequest request) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        food.setName(request.getName());
        food.setCalories(defaultZero(request.getCalories()));
        food.setProtein(defaultZero(request.getProtein()));
        food.setCarbs(defaultZero(request.getCarbs()));
        food.setFat(defaultZero(request.getFat()));
        food.setFiber(request.getFiber());
        food.setSugar(request.getSugar());
        food.setSodium(request.getSodium());
        food.setPotassium(request.getPotassium());
        food.setCalcium(request.getCalcium());
        food.setIron(request.getIron());
        food.setVitaminC(request.getVitaminC());
        food.setWater(request.getWater());
        food.setUnit(request.getUnit());
        if (request.getServingSizeGrams() != null) {
            food.setServingSizeGrams(request.getServingSizeGrams());
        }
        if (request.getDataSourceType() != null) {
            food.setDataSourceType(sourceType(request.getDataSourceType()));
        }
        if (request.getDataSourceName() != null) {
            food.setDataSourceName(request.getDataSourceName().isBlank()
                    ? null
                    : request.getDataSourceName().trim());
        }
        if (request.getVerified() != null) {
            food.setVerified(request.getVerified());
        }
        food.setImageUrl(mediaStorageService.store(
                food.getImageUrl(),
                request.getImageUrl(),
                ImageReferences.foodPath(food.getId()),
                "foods",
                food.getId()
        ));

        Food saved = foodRepository.save(food);

        return nutritionMapper.toFoodResponse(saved);
    }

    public void softDelete(String id) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        food.setActive(false);

        foodRepository.save(food);
    }

    public FoodResponse restore(String id) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Food not found"));

        food.setActive(true);

        Food saved = foodRepository.save(food);

        return nutritionMapper.toFoodResponse(saved);
    }

    private double defaultZero(Double value) {
        return value == null ? 0.0 : value;
    }

    private String sourceType(String value) {
        String normalized = value == null || value.isBlank()
                ? "ESTIMATED"
                : value.trim().toUpperCase();
        if (!java.util.Set.of(
                "VERIFIED_DATABASE",
                "PRODUCT_LABEL",
                "RECIPE_CALCULATED",
                "COMMUNITY",
                "ESTIMATED"
        ).contains(normalized)) {
            throw new IllegalArgumentException("Nguồn dữ liệu thực phẩm không hợp lệ");
        }
        return normalized;
    }
}

