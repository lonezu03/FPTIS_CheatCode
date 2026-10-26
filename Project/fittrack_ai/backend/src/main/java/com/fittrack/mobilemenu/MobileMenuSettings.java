package com.fittrack.mobilemenu;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name = "mobile_menu_settings") @Getter @Setter
public class MobileMenuSettings {
    @Id private Integer id;
    @Version private Long version;
    @Column(name = "modules_json", nullable = false, columnDefinition = "text")
    private String modulesJson;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;
    @Column(name = "updated_by") private String updatedBy;
}
