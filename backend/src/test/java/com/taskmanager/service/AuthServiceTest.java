package com.taskmanager.service;

import com.taskmanager.dto.AuthResponse;
import com.taskmanager.dto.LoginRequest;
import com.taskmanager.dto.RegisterRequest;
import com.taskmanager.entity.User;
import com.taskmanager.exception.EmailAlreadyExistsException;
import com.taskmanager.exception.InvalidCredentialsException;
import com.taskmanager.repository.UserRepository;
import com.taskmanager.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthService authService;

    private User existingUser;

    @BeforeEach
    void setUp() {
        existingUser = User.builder()
                .id(1L)
                .email("jane@doe.com")
                .password("hashed-password")
                .fullName("Jane Doe")
                .createdAt(Instant.now())
                .build();
    }

    @Test
    void register_success_returnsTokenAndUser() {
        RegisterRequest request = new RegisterRequest("jane@doe.com", "Sup3rSecret!", "Jane Doe");

        when(userRepository.existsByEmail("jane@doe.com")).thenReturn(false);
        when(passwordEncoder.encode("Sup3rSecret!")).thenReturn("hashed-password");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(1L);
            return u;
        });
        when(jwtService.generateToken(any(UserDetails.class))).thenReturn("mock-jwt-token");

        AuthResponse response = authService.register(request);

        assertThat(response.getToken()).isEqualTo("mock-jwt-token");
        assertThat(response.getUser().getId()).isEqualTo(1L);
        assertThat(response.getUser().getEmail()).isEqualTo("jane@doe.com");
        assertThat(response.getUser().getFullName()).isEqualTo("Jane Doe");

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        assertThat(userCaptor.getValue().getPassword()).isEqualTo("hashed-password");
    }

    @Test
    void register_duplicateEmail_throwsEmailAlreadyExistsException() {
        RegisterRequest request = new RegisterRequest("jane@doe.com", "Sup3rSecret!", "Jane Doe");
        when(userRepository.existsByEmail("jane@doe.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(EmailAlreadyExistsException.class);

        verify(userRepository, never()).save(any());
    }

    @Test
    void register_normalizesEmailToLowercaseAndTrimmed() {
        RegisterRequest request = new RegisterRequest("  Jane@Doe.com  ", "Sup3rSecret!", "Jane Doe");
        when(userRepository.existsByEmail("jane@doe.com")).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(jwtService.generateToken(any(UserDetails.class))).thenReturn("token");

        authService.register(request);

        verify(userRepository).existsByEmail("jane@doe.com");
    }

    @Test
    void login_success_returnsTokenAndUser() {
        LoginRequest request = new LoginRequest("jane@doe.com", "Sup3rSecret!");
        when(userRepository.findByEmail("jane@doe.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("Sup3rSecret!", "hashed-password")).thenReturn(true);
        when(jwtService.generateToken(any(UserDetails.class))).thenReturn("mock-jwt-token");

        AuthResponse response = authService.login(request);

        assertThat(response.getToken()).isEqualTo("mock-jwt-token");
        assertThat(response.getUser().getEmail()).isEqualTo("jane@doe.com");
    }

    @Test
    void login_unknownEmail_throwsInvalidCredentialsException() {
        LoginRequest request = new LoginRequest("nobody@doe.com", "Sup3rSecret!");
        when(userRepository.findByEmail("nobody@doe.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void login_wrongPassword_throwsInvalidCredentialsException() {
        LoginRequest request = new LoginRequest("jane@doe.com", "wrong-password");
        when(userRepository.findByEmail("jane@doe.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("wrong-password", "hashed-password")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class);

        verify(jwtService, never()).generateToken(any());
    }
}
