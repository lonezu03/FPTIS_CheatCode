package com.fittrack.schedule.service;

import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.schedule.dto.ScheduleDtos.ScheduleRequest;
import com.fittrack.schedule.dto.ScheduleDtos.ScheduleResponse;
import com.fittrack.schedule.entity.ScheduleItem;
import com.fittrack.schedule.repository.ScheduleRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ScheduleService {
    private final ScheduleRepository repository;

    @Transactional(readOnly = true)
    public List<ScheduleResponse> getMine(User user) {
        return repository.findByUserOrderByStartAtAsc(user).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public ScheduleResponse create(User user, ScheduleRequest request) {
        ScheduleItem item = new ScheduleItem();
        item.setUser(user);
        apply(item, request);
        return toResponse(repository.save(item));
    }

    @Transactional
    public ScheduleResponse update(User user, String id, ScheduleRequest request) {
        ScheduleItem item = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch"));
        apply(item, request);
        return toResponse(repository.save(item));
    }

    @Transactional
    public void delete(User user, String id) {
        ScheduleItem item = repository.findByIdAndUser(id, user)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch"));
        repository.delete(item);
    }

    private void apply(ScheduleItem item, ScheduleRequest request) {
        item.setTitle(request.title().trim());
        item.setDescription(request.description() == null ? null : request.description().trim());
        item.setCategory(request.category() == null ? ScheduleItem.ScheduleCategory.PERSONAL : request.category());
        item.setStartAt(request.startAt());
        item.setEndAt(request.endAt());
        item.setRepeatRule(request.repeatRule() == null ? ScheduleItem.RepeatRule.NONE : request.repeatRule());
        item.setDaysOfWeek(request.daysOfWeek() == null ? null : request.daysOfWeek().trim());
        item.setReminderMinutes(request.reminderMinutes() == null ? 10 : request.reminderMinutes());
        item.setReminderEnabled(request.reminderEnabled() == null || request.reminderEnabled());
        item.setEnabled(request.enabled() == null || request.enabled());
    }

    private ScheduleResponse toResponse(ScheduleItem item) {
        return new ScheduleResponse(
                item.getId(), item.getTitle(), item.getDescription(), item.getCategory(), item.getStartAt(),
                item.getEndAt(), item.getRepeatRule(), item.getDaysOfWeek(), item.getReminderMinutes(),
                Boolean.TRUE.equals(item.getReminderEnabled()), Boolean.TRUE.equals(item.getEnabled()),
                item.getLastRemindedAt(), item.getCreatedAt()
        );
    }
}
