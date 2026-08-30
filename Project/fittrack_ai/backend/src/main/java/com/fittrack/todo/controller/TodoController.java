package com.fittrack.todo.controller;

import com.fittrack.todo.dto.TodoDtos.TodoRequest;
import com.fittrack.todo.dto.TodoDtos.TodoResponse;
import com.fittrack.todo.service.TodoService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/todos")
@RequiredArgsConstructor
public class TodoController {
    private final TodoService todoService;

    @GetMapping
    public List<TodoResponse> getMine(
            @AuthenticationPrincipal User user,
            @RequestParam(required = false) String view,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) com.fittrack.todo.entity.Todo.TodoStatus status
    ) {
        return todoService.getMine(user, view, category, status);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TodoResponse create(@AuthenticationPrincipal User user, @Valid @RequestBody TodoRequest request) {
        return todoService.create(user, request);
    }

    @PatchMapping("/{id}")
    public TodoResponse update(@AuthenticationPrincipal User user, @PathVariable String id, @Valid @RequestBody TodoRequest request) {
        return todoService.update(user, id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal User user, @PathVariable String id) {
        todoService.delete(user, id);
    }
}
