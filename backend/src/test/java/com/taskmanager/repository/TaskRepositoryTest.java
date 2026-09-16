package com.taskmanager.repository;

import com.taskmanager.entity.Task;
import com.taskmanager.entity.TaskStatus;
import com.taskmanager.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.ActiveProfiles;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

// Replace.NONE keeps the explicit H2 datasource from application-test.yml
// (ddl-auto=create-drop) instead of @DataJpaTest's own auto-configured
// embedded database, whose schema wasn't ready before this test's
// IDENTITY-generated inserts ran.
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
class TaskRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private TaskRepository taskRepository;

    private User owner;
    private User otherUser;

    @BeforeEach
    void setUp() {
        owner = entityManager.persist(User.builder()
                .email("owner@doe.com")
                .password("hashed")
                .fullName("Owner")
                .createdAt(Instant.now())
                .build());

        otherUser = entityManager.persist(User.builder()
                .email("other@doe.com")
                .password("hashed")
                .fullName("Other")
                .createdAt(Instant.now())
                .build());

        Instant base = Instant.now().minusSeconds(60);
        persistTask(owner, "Buy milk", "groceries and stuff", TaskStatus.TODO, base.plusSeconds(1));
        persistTask(owner, "Write report", "quarterly summary", TaskStatus.IN_PROGRESS, base.plusSeconds(2));
        persistTask(owner, "Ship report", "final version", TaskStatus.DONE, base.plusSeconds(3));
        // Belongs to a different user; must never leak into owner's results.
        persistTask(otherUser, "Report from other user", "should not appear", TaskStatus.TODO, base.plusSeconds(4));

        entityManager.flush();
    }

    private void persistTask(User user, String title, String description, TaskStatus status, Instant createdAt) {
        Task task = Task.builder()
                .title(title)
                .description(description)
                .status(status)
                .user(user)
                .createdAt(createdAt)
                .updatedAt(createdAt)
                .build();
        entityManager.persist(task);
    }

    @Test
    void search_noFilters_returnsAllOwnerTasksNewestFirst() {
        List<Task> results = taskRepository.search(owner, null, null);

        assertThat(results).hasSize(3);
        assertThat(results).allMatch(t -> t.getUser().getId().equals(owner.getId()));
        // Newest first (createdAt DESC) => last inserted ("Ship report") comes first.
        assertThat(results.get(0).getTitle()).isEqualTo("Ship report");
        assertThat(results.get(2).getTitle()).isEqualTo("Buy milk");
    }

    @Test
    void search_filterByStatusOnly() {
        List<Task> results = taskRepository.search(owner, TaskStatus.IN_PROGRESS, null);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getTitle()).isEqualTo("Write report");
    }

    @Test
    void search_filterBySearchTextOnly_matchesTitleOrDescriptionCaseInsensitive() {
        List<Task> results = taskRepository.search(owner, null, "REPORT");

        assertThat(results).hasSize(2);
        assertThat(results).extracting(Task::getTitle)
                .containsExactlyInAnyOrder("Write report", "Ship report");
    }

    @Test
    void search_filterBySearchTextMatchingDescriptionOnly() {
        List<Task> results = taskRepository.search(owner, null, "groceries");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getTitle()).isEqualTo("Buy milk");
    }

    @Test
    void search_combinedStatusAndSearch() {
        List<Task> results = taskRepository.search(owner, TaskStatus.DONE, "report");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getTitle()).isEqualTo("Ship report");
    }

    @Test
    void search_combinedStatusAndSearch_noMatch_returnsEmpty() {
        List<Task> results = taskRepository.search(owner, TaskStatus.TODO, "report");

        assertThat(results).isEmpty();
    }

    @Test
    void search_neverReturnsOtherUsersTasks() {
        List<Task> results = taskRepository.search(owner, null, "Report from other user");

        assertThat(results).isEmpty();
    }

    @Test
    void findByIdAndUser_returnsEmptyForAnotherUsersTask() {
        Task ownerTask = taskRepository.search(owner, null, null).get(0);

        assertThat(taskRepository.findByIdAndUser(ownerTask.getId(), otherUser)).isEmpty();
        assertThat(taskRepository.findByIdAndUser(ownerTask.getId(), owner)).isPresent();
    }
}
