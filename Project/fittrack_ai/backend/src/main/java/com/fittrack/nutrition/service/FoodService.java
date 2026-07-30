package com.fittrack.nutrition.service;

import com.fittrack.nutrition.dto.CreateFoodRequest;
import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.UpdateFoodRequest;
import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.mapper.NutritionMapper;
import com.fittrack.nutrition.repository.FoodRepository;
import com.fittrack.common.media.ImageReferences;
import com.fittrack.common.dto.CatalogReviewRequest;
import com.fittrack.lunch.service.LunchNotificationService;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class FoodService {

    private final FoodRepository foodRepository;
    private final NutritionMapper nutritionMapper;
    private final LunchNotificationService notificationService;

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
                .fiber(defaultZero(request.getFiber()))
                .sugar(defaultZero(request.getSugar()))
                .sodium(defaultZero(request.getSodium()))
                .potassium(defaultZero(request.getPotassium()))
                .calcium(defaultZero(request.getCalcium()))
                .iron(defaultZero(request.getIron()))
                .vitaminC(defaultZero(request.getVitaminC()))
                .water(defaultZero(request.getWater()))
                .unit(request.getUnit())
                .imageUrl(ImageReferences.normalizeForStorage(request.getImageUrl()))
                .custom(true)
                .active(true)
                .approvalStatus("APPROVED")
                .build();

        Food saved = foodRepository.save(food);

        return nutritionMapper.toFoodResponse(saved);
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
                .fiber(defaultZero(request.getFiber()))
                .sugar(defaultZero(request.getSugar()))
                .sodium(defaultZero(request.getSodium()))
                .potassium(defaultZero(request.getPotassium()))
                .calcium(defaultZero(request.getCalcium()))
                .iron(defaultZero(request.getIron()))
                .vitaminC(defaultZero(request.getVitaminC()))
                .water(defaultZero(request.getWater()))
                .unit(request.getUnit())
                .imageUrl(
                        ImageReferences.normalizeForStorage(
                                request.getImageUrl()
                        )
                )
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
        food.setFiber(defaultZero(request.getFiber()));
        food.setSugar(defaultZero(request.getSugar()));
        food.setSodium(defaultZero(request.getSodium()));
        food.setPotassium(defaultZero(request.getPotassium()));
        food.setCalcium(defaultZero(request.getCalcium()));
        food.setIron(defaultZero(request.getIron()));
        food.setVitaminC(defaultZero(request.getVitaminC()));
        food.setWater(defaultZero(request.getWater()));
        food.setUnit(request.getUnit());
        food.setImageUrl(ImageReferences.resolveStoredValue(
                food.getImageUrl(),
                request.getImageUrl(),
                ImageReferences.foodPath(food.getId())
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
}

