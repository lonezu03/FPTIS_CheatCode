package com.fittrack.nutrition.planning;
import com.fittrack.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity @Table(name="nutrition_grocery_weeks",uniqueConstraints=@UniqueConstraint(columnNames={"user_id","week"}))
@Getter @Setter @NoArgsConstructor
public class GroceryWeek {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @Version private long version;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id",nullable=false) private User user;
    @Column(nullable=false) private LocalDate week;
    @Column(nullable=false,columnDefinition="TEXT") private String items="[]";
}
