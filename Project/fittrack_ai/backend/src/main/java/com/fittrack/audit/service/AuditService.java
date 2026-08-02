package com.fittrack.audit.service;

import com.fittrack.audit.entity.AuditEvent;
import com.fittrack.audit.repository.AuditEventRepository;
import com.fittrack.common.observability.RequestContext;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditEventRepository repository;
    private final ObjectMapper objectMapper;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void record(
            User actor,
            String action,
            String resourceType,
            String resourceId,
            Map<String, ?> details
    ) {
        RequestContext.Details request = RequestContext.get();
        repository.save(AuditEvent.builder()
                .actorId(actor == null ? null : actor.getId())
                .actorEmail(actor == null ? null : actor.getEmail())
                .action(action)
                .resourceType(resourceType)
                .resourceId(resourceId)
                .details(serialize(details))
                .requestId(request == null ? null : request.requestId())
                .clientAddress(request == null ? null : request.clientAddress())
                .build());
    }

    private String serialize(Map<String, ?> details) {
        try {
            String value = objectMapper.writeValueAsString(details == null ? Map.of() : details);
            return value.length() <= 8_000 ? value : value.substring(0, 8_000);
        } catch (JacksonException exception) {
            return "{\"serializationError\":true}";
        }
    }
}
