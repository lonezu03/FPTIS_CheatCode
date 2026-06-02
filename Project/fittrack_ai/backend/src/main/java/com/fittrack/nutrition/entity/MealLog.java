package com.fittrack.nutrition.entity;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "meal_logs")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MealLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    private User user;

    private String mealType;

    private LocalDate logDate;

    private Double totalCalories;

    private Double totalProtein;

    private Double totalCarbs;

    private Double totalFat;

    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "mealLog", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<MealItem> items = new ArrayList<>();

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();

        if (this.logDate == null) {
            this.logDate = LocalDate.now();
        }
    }
}

