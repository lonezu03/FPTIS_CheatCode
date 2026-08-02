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

    private Double quantity;

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

