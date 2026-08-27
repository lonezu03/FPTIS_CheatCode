package com.fittrack.todo.repository;

import com.fittrack.todo.entity.Todo;
import com.fittrack.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TodoRepository extends JpaRepository<Todo, String> {
    List<Todo> findByUserAndStatusNotOrderByDueAtAscCreatedAtDesc(User user, Todo.TodoStatus status);
    List<Todo> findByUserOrderByDueAtAscCreatedAtDesc(User user);
    Optional<Todo> findByIdAndUser(String id, User user);
}
