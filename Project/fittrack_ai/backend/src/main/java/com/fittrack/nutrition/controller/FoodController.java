package com.fittrack.nutrition.controller;

import com.fittrack.nutrition.dto.CreateFoodRequest;
import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.UpdateFoodRequest;
import com.fittrack.nutrition.service.FoodService;
import com.fittrack.common.dto.CatalogReviewRequest;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.util.List;

@RestController
@RequestMapping("/api/foods")
@RequiredArgsConstructor
public class FoodController {

    private final FoodService foodService;

    @GetMapping
    public List<FoodResponse> getFoods(
            @AuthenticationPrincipal User user,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean includeInactive
    ) {
        boolean admin = "ADMIN".equalsIgnoreCase(user.getRole());
        return foodService.getFoods(
                keyword,
                admin && Boolean.TRUE.equals(includeInactive)
        );
    }

    @GetMapping("/mine")
    public List<FoodResponse> getMySubmissions(
            @AuthenticationPrincipal User user
    ) {
        return foodService.getMySubmissions(user);
    }

    @PostMapping
    public FoodResponse create(@Valid @RequestBody CreateFoodRequest request) {
        return foodService.create(request);
    }

    @PostMapping("/suggestions")
    public FoodResponse suggest(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody CreateFoodRequest request
    ) {
        return foodService.createSuggestion(user, request);
    }

    @PatchMapping("/{id}/review")
    public FoodResponse review(
            @PathVariable String id,
            @Valid @RequestBody CatalogReviewRequest request
    ) {
        return foodService.review(id, request);
    }

    @PutMapping("/{id}")
    public FoodResponse update(
            @PathVariable String id,
            @Valid @RequestBody UpdateFoodRequest request
    ) {
        return foodService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable String id) {
        foodService.softDelete(id);
    }

    @PatchMapping("/{id}/restore")
    public FoodResponse restore(@PathVariable String id) {
        return foodService.restore(id);
    }
}

