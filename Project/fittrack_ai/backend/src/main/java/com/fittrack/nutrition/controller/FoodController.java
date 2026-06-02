package com.fittrack.nutrition.controller;

import com.fittrack.nutrition.dto.CreateFoodRequest;
import com.fittrack.nutrition.dto.FoodResponse;
import com.fittrack.nutrition.dto.UpdateFoodRequest;
import com.fittrack.nutrition.service.FoodService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/foods")
@RequiredArgsConstructor
public class FoodController {

    private final FoodService foodService;

    @GetMapping
    public List<FoodResponse> getFoods(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean includeInactive
    ) {
        return foodService.getFoods(keyword, includeInactive);
    }

    @PostMapping
    public FoodResponse create(@RequestBody CreateFoodRequest request) {
        return foodService.create(request);
    }

    @PutMapping("/{id}")
    public FoodResponse update(
            @PathVariable String id,
            @RequestBody UpdateFoodRequest request
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

