package com.taskmanager.service;

import com.taskmanager.dto.TaskRequest;
import com.taskmanager.dto.TaskResponse;
import com.taskmanager.entity.Task;
import com.taskmanager.entity.TaskStatus;
import com.taskmanager.entity.User;
import com.taskmanager.exception.TaskNotFoundException;
import com.taskmanager.repository.TaskRepository;
import com.taskmanager.repository.UserRepository;
import com.taskmanager.security.UserPrincipal;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private TaskService taskService;

    private User currentUser;

    @BeforeEach
    void setUp() {
        currentUser = User.builder().id(1L).email("jane@doe.com").fullName("Jane Doe").build();

        UserPrincipal principal = new UserPrincipal(currentUser);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));

        lenientStub();
    }

    private void lenientStub() {
        lenient().when(userRepository.findById(1L)).thenReturn(Optional.of(currentUser));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void getTasks_delegatesToRepositorySearchScopedToCurrentUser() {
        Task task = Task.builder().id(10L).title("Write report").description("Q3")
                .status(TaskStatus.TODO).user(currentUser)
                .createdAt(Instant.now()).updatedAt(Instant.now()).build();

        when(taskRepository.search(currentUser, TaskStatus.TODO, "report")).thenReturn(List.of(task));

        List<TaskResponse> result = taskService.getTasks(TaskStatus.TODO, "report");

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getTitle()).isEqualTo("Write report");
        verify(taskRepository).search(currentUser, TaskStatus.TODO, "report");
    }

    @Test
    void createTask_success_defaultsStatusToTodoWhenNull() {
        TaskRequest request = TaskRequest.builder().title("New task").description("desc").status(null).build();

        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> {
            Task t = invocation.getArgument(0);
            t.setId(100L);
            t.setCreatedAt(Instant.now());
            t.setUpdatedAt(Instant.now());
            return t;
        });

        TaskResponse response = taskService.createTask(request);

        assertThat(response.getId()).isEqualTo(100L);
        assertThat(response.getStatus()).isEqualTo(TaskStatus.TODO);
        assertThat(response.getTitle()).isEqualTo("New task");
    }

    @Test
    void createTask_success_respectsExplicitStatus() {
        TaskRequest request = TaskRequest.builder().title("New task").status(TaskStatus.IN_PROGRESS).build();
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TaskResponse response = taskService.createTask(request);

        assertThat(response.getStatus()).isEqualTo(TaskStatus.IN_PROGRESS);
    }

    @Test
    void updateTask_success_updatesFields() {
        Task existing = Task.builder().id(10L).title("Old").description("Old desc")
                .status(TaskStatus.TODO).user(currentUser)
                .createdAt(Instant.now()).updatedAt(Instant.now()).build();
        TaskRequest request = TaskRequest.builder().title("Updated").description("Updated desc")
                .status(TaskStatus.DONE).build();

        when(taskRepository.findByIdAndUser(10L, currentUser)).thenReturn(Optional.of(existing));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TaskResponse response = taskService.updateTask(10L, request);

        assertThat(response.getTitle()).isEqualTo("Updated");
        assertThat(response.getDescription()).isEqualTo("Updated desc");
        assertThat(response.getStatus()).isEqualTo(TaskStatus.DONE);
    }

    @Test
    void updateTask_notFound_throwsTaskNotFoundException() {
        TaskRequest request = TaskRequest.builder().title("Updated").build();
        when(taskRepository.findByIdAndUser(999L, currentUser)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.updateTask(999L, request))
                .isInstanceOf(TaskNotFoundException.class);

        verify(taskRepository, never()).save(any());
    }

    @Test
    void updateTask_belongingToAnotherUser_throwsTaskNotFoundException() {
        // findByIdAndUser is scoped to currentUser, so another user's task id resolves to empty.
        TaskRequest request = TaskRequest.builder().title("Hijack attempt").build();
        when(taskRepository.findByIdAndUser(55L, currentUser)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.updateTask(55L, request))
                .isInstanceOf(TaskNotFoundException.class);
    }

    @Test
    void deleteTask_success_deletesTask() {
        Task existing = Task.builder().id(10L).title("Task").user(currentUser).status(TaskStatus.TODO).build();
        when(taskRepository.findByIdAndUser(10L, currentUser)).thenReturn(Optional.of(existing));

        taskService.deleteTask(10L);

        verify(taskRepository).delete(existing);
    }

    @Test
    void deleteTask_notFound_throwsTaskNotFoundException() {
        when(taskRepository.findByIdAndUser(999L, currentUser)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.deleteTask(999L))
                .isInstanceOf(TaskNotFoundException.class);

        verify(taskRepository, never()).delete(any(Task.class));
    }
}
