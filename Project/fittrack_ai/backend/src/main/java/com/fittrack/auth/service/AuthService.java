package com.fittrack.auth.service;

import com.fittrack.auth.dto.AuthResponse;
import com.fittrack.auth.dto.LoginRequest;
import com.fittrack.auth.dto.RegisterRequest;
import com.fittrack.common.security.JwtService;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already exists");
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .gender(request.getGender())
                .age(request.getAge())
                .height(request.getHeight())
                .weight(request.getWeight())
                .goal(request.getGoal())
                .activityLevel(request.getActivityLevel())
                .role("USER")
                .build();

        User savedUser = userRepository.save(user);
        String token = jwtService.generateToken(savedUser);

        return buildAuthResponse(savedUser, token);
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        boolean passwordMatches = passwordEncoder.matches(
                request.getPassword(),
                user.getPassword()
        );

        if (!passwordMatches) {
            throw new BadCredentialsException("Invalid email or password");
        }

        String token = jwtService.generateToken(user);

        return buildAuthResponse(user, token);
    }

    private AuthResponse buildAuthResponse(User user, String token) {
        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .build();
    }
}