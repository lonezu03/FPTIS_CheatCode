package com.fittrack.nutrition.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "meal_items")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MealItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    private MealLog mealLog;

    @ManyToOne(fetch = FetchType.LAZY)
    private Food food;

    private String foodNameSnapshot;
    private String foodUnitSnapshot;
    private String foodSourceSnapshot;
    private String foodSourceTypeSnapshot;
    private Boolean foodVerifiedSnapshot;
    private Double servingSizeSnapshot;

    @PrePersist
    public void snapshotFood() {
        if (food != null && foodNameSnapshot == null) {
            foodNameSnapshot = food.getName();
            foodUnitSnapshot = food.getUnit();
            foodSourceSnapshot = food.getDataSourceName();
            foodSourceTypeSnapshot = food.getDataSourceType();
            foodVerifiedSnapshot = food.getVerified();
            servingSizeSnapshot = food.getServingSizeGrams();
        }
    }

    private Double quantity;

    private Double servingAmount;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String servingUnit = "SERVING";

    private Double gramsEquivalent;

    private Double calories;

    private Double protein;

    private Double carbs;

    private Double fat;

    private Double fiber;

    private Double sugar;

    private Double sodium;

    private Double potassium;

    private Double calcium;

    private Double iron;

    @Column(name = "vitamin_c")
    private Double vitaminC;

    private Double water;
}

