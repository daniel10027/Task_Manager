package com.taskmanager.repository;

import com.taskmanager.entity.Task;
import com.taskmanager.entity.TaskStatus;
import com.taskmanager.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByUserOrderByCreatedAtDesc(User user);

    Optional<Task> findByIdAndUser(Long id, User user);

    /**
     * Combines an optional exact status match with an optional case-insensitive
     * substring search across title/description, scoped to the owning user,
     * ordered by creation date descending (newest first).
     */
    @Query("SELECT t FROM Task t " +
            "WHERE t.user = :user " +
            "AND (:status IS NULL OR t.status = :status) " +
            "AND (:search IS NULL OR :search = '' " +
            "     OR LOWER(t.title) LIKE LOWER(CONCAT('%', :search, '%')) " +
            "     OR LOWER(t.description) LIKE LOWER(CONCAT('%', :search, '%'))) " +
            "ORDER BY t.createdAt DESC")
    List<Task> search(@Param("user") User user,
                       @Param("status") TaskStatus status,
                       @Param("search") String search);
}
