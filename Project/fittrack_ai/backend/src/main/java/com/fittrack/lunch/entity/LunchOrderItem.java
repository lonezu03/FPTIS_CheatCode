package com.fittrack.lunch.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "lunch_order_items")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LunchOrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private LunchOrder order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "menu_item_id", nullable = false)
    private LunchMenuItem menuItem;

    @Column(nullable = false)
    private String itemNameSnapshot;

    @Column(nullable = false)
    private Integer sortOrder;
}
