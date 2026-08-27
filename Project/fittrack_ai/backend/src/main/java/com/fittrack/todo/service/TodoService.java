package com.fittrack.todo.service;

import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.todo.dto.TodoDtos.TodoRequest;
import com.fittrack.todo.dto.TodoDtos.TodoResponse;
import com.fittrack.todo.entity.Todo;
import com.fittrack.todo.repository.TodoRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TodoService {
    private final TodoRepository repository;

    @Transactional(readOnly = true)
    public List<TodoResponse> getMine(User user) {
        return repository.findByUserOrderByDueAtAscCreatedAtDesc(user).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public TodoResponse create(User user, TodoRequest request) {
        Todo todo = new Todo();
        todo.setUser(user);
        apply(todo, request);
        return toResponse(repository.save(todo));
    }

    @Transactional
    public TodoResponse update(User user, String id, TodoRequest request) {
        Todo todo = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc"));
        apply(todo, request);
        return toResponse(repository.save(todo));
    }

    @Transactional
    public void delete(User user, String id) {
        Todo todo = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc"));
        repository.delete(todo);
    }

    private void apply(Todo todo, TodoRequest request) {
        todo.setTitle(request.title().trim());
        todo.setDescription(request.description() == null ? null : request.description().trim());
        if (request.status() != null) todo.setStatus(request.status());
        if (request.priority() != null) todo.setPriority(request.priority());
        todo.setDueAt(request.dueAt());
        todo.setReminderAt(request.reminderAt());
        todo.setReminderEnabled(Boolean.TRUE.equals(request.reminderEnabled()));
        if (todo.getReminderAt() == null) todo.setReminderEnabled(false);
        if (todo.getStatus() == null) todo.setStatus(Todo.TodoStatus.OPEN);
        if (todo.getPriority() == null) todo.setPriority(Todo.TodoPriority.MEDIUM);
    }

    private TodoResponse toResponse(Todo todo) {
        return new TodoResponse(
                todo.getId(), todo.getTitle(), todo.getDescription(), todo.getStatus(),
                todo.getPriority(), todo.getDueAt(), todo.getReminderAt(),
                Boolean.TRUE.equals(todo.getReminderEnabled()), todo.getCreatedAt(), todo.getUpdatedAt()
        );
    }
}
