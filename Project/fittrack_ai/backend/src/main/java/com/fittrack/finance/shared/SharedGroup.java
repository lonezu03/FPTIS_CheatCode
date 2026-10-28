package com.fittrack.finance.shared;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name="shared_expense_groups") @Getter @Setter
public class SharedGroup {
    @Id @GeneratedValue(strategy=GenerationType.UUID) private String id;
    @Column(nullable=false) private String ownerId;
    @Column(nullable=false,length=160) private String name;
    @Column(length=1000) private String description;
    @Column(nullable=false) private boolean archived;
    @Column(nullable=false) private LocalDateTime createdAt;
    @Version private Long version;
    // Force a version increment for every ledger/member mutation under the group lock.
    @Column(nullable=false) private long revision;
}
