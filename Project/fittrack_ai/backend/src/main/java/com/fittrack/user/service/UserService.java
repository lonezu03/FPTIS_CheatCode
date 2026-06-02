package com.fittrack.user.service;

import com.fittrack.user.dto.UpdateUserProfileRequest;
import com.fittrack.user.dto.UserProfileResponse;
import com.fittrack.user.entity.User;
import com.fittrack.user.mapper.UserMapper;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public UserProfileResponse getProfile(User user) {
        return userMapper.toProfileResponse(user);
    }

    public UserProfileResponse updateProfile(User user, UpdateUserProfileRequest request) {
        user.setFullName(request.getFullName());
        user.setGender(request.getGender());
        user.setAge(request.getAge());
        user.setHeight(request.getHeight());
        user.setWeight(request.getWeight());
        user.setGoal(request.getGoal());
        user.setActivityLevel(request.getActivityLevel());

        User saved = userRepository.save(user);

        return userMapper.toProfileResponse(saved);
    }
}

