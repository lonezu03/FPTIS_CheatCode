package com.fittrack.nutrition.planning;

import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity @Table(name="nutrition_planned_meals") @Getter @Setter @NoArgsConstructor
public class PlannedMeal {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @Version private long version;
    @ManyToOne(fetch=FetchType.LAZY, optional=false) @JoinColumn(name="user_id",nullable=false) private User user;
    @Column(nullable=false) private LocalDate date;
    @Column(nullable=false,length=20) private String mealType;
    @Column(nullable=false,length=160) private String name;
    @Column(length=1000) private String notes;
    @Column(nullable=false,columnDefinition="TEXT") private String snapshot;
    private String loggedMealId;
    @Column(nullable=false) private LocalDateTime createdAt = LocalDateTime.now();
}
