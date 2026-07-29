package com.fittrack.user.service;

import com.fittrack.common.exception.ConflictException;
import com.fittrack.user.dto.AdminUserDtos.UpdateAdminUserRequest;
import com.fittrack.user.entity.User;
import com.fittrack.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminUserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AdminUserService service;

    @BeforeEach
    void setUp() {
        service = new AdminUserService(userRepository, passwordEncoder);
    }

    @Test
    void adminCannotDemoteOwnAccount() {
        User admin = user("admin-id", "ADMIN", true);
        when(userRepository.findByIdForUpdate(admin.getId()))
                .thenReturn(Optional.of(admin));

        assertThrows(
                ConflictException.class,
                () -> service.updateUser(
                        admin,
                        admin.getId(),
                        new UpdateAdminUserRequest("Admin", "USER", true)
                )
        );
        verify(userRepository, never()).save(any());
    }

    @Test
    void systemMustKeepAtLeastOneActiveAdmin() {
        User currentAdmin = user("admin-1", "ADMIN", true);
        User targetAdmin = user("admin-2", "ADMIN", true);
        when(userRepository.findByIdForUpdate(targetAdmin.getId()))
                .thenReturn(Optional.of(targetAdmin));
        when(userRepository.countByRoleIgnoreCaseAndActiveTrue("ADMIN"))
                .thenReturn(1L);

        assertThrows(
                ConflictException.class,
                () -> service.updateUser(
                        currentAdmin,
                        targetAdmin.getId(),
                        new UpdateAdminUserRequest("Admin 2", "ADMIN", false)
                )
        );
        verify(userRepository, never()).save(any());
    }

    @Test
    void adminCanPromoteAnActiveUser() {
        User currentAdmin = user("admin-1", "ADMIN", true);
        User targetUser = user("user-1", "USER", true);
        when(userRepository.findByIdForUpdate(targetUser.getId()))
                .thenReturn(Optional.of(targetUser));
        when(userRepository.save(targetUser)).thenReturn(targetUser);

        var response = service.updateUser(
                currentAdmin,
                targetUser.getId(),
                new UpdateAdminUserRequest("Thành viên", "ADMIN", true)
        );

        assertEquals("ADMIN", response.role());
        assertTrue(response.active());
        verify(userRepository).save(targetUser);
    }

    private User user(String id, String role, boolean active) {
        return User.builder()
                .id(id)
                .email(id + "@fittrack.test")
                .password("encoded")
                .fullName(id)
                .role(role)
                .active(active)
                .build();
    }
}
