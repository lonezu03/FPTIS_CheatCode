package com.fittrack.catalogimport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import jakarta.persistence.LockModeType;
import java.util.*;
public interface CatalogImportRepository extends JpaRepository<CatalogImportBatch,String> {
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select b from CatalogImportBatch b where b.id=:id and b.actorId=:actor")
    Optional<CatalogImportBatch> locked(String id,String actor);
    List<CatalogImportBatch> findTop30ByActorIdAndKindOrderByCreatedAtDesc(String actorId,String kind);
}
