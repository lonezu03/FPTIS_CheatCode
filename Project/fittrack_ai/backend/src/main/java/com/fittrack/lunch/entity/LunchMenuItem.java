package com.fittrack.lunch.entity;

import com.fittrack.nutrition.entity.Food;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "lunch_menu_items",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_lunch_menu_items_menu_sort",
                columnNames = {"menu_id", "sort_order"}
        )
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LunchMenuItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "menu_id", nullable = false)
    private LunchMenu menu;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LunchMenuItemType type;

    @Column(nullable = false)
    private Integer sortOrder;

    @Column(columnDefinition = "TEXT")
    private String imageUrl;

    private Double calories;

    private Double protein;

    private Double carbs;

    private Double fat;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nutrition_food_id")
    private Food nutritionFood;
}
