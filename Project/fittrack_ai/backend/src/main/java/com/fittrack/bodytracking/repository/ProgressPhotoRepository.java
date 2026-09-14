package com.fittrack.bodytracking.repository;

import com.fittrack.bodytracking.entity.ProgressPhoto;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ProgressPhotoRepository extends JpaRepository<ProgressPhoto, String> {
    List<ProgressPhoto> findByUserOrderByTakenDateDescCreatedAtDesc(User user);
    Optional<ProgressPhoto> findByIdAndUser(String id, User user);
}
