package com.fittrack.nutrition.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "nutrition_collection_items")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NutritionCollectionItem {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "collection_id", nullable = false)
    private NutritionCollection collection;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "food_id", nullable = false)
    private Food food;

    @Column(nullable = false)
    private Double servingAmount;
    @Column(nullable = false, length = 20)
    private String servingUnit;
    @Column(nullable = false)
    private Integer itemOrder;
}
