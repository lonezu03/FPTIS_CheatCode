package com.fittrack.catalogimport;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name="catalog_import_batches") @Getter @Setter @NoArgsConstructor
public class CatalogImportBatch {
    @Id private String id;
    @Column(nullable=false) private String actorId;
    @Column(nullable=false) private String kind;
    @Column(nullable=false, columnDefinition="TEXT") private String snapshot;
    @Column(nullable=false) private LocalDateTime createdAt;
    private LocalDateTime committedAt;
    private String commitDigest;
    @Column(length=64) private String sourceDigest;
    @Version private Long version;
}
