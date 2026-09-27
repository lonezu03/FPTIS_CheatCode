package com.fittrack.journal.controller;

import com.fittrack.common.dto.PageResponse;
import com.fittrack.journal.dto.JournalDtos.*;
import com.fittrack.journal.entity.*;
import com.fittrack.journal.service.JournalService;
import com.fittrack.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import java.nio.charset.StandardCharsets;
import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/api/journal")
@RequiredArgsConstructor
public class JournalController {
    private final JournalService service;

    @GetMapping("/today") public TodayResponse today(@AuthenticationPrincipal User user) { return service.today(user); }
    @PostMapping("/today/skip") public TodayResponse skip(@AuthenticationPrincipal User user) { return service.skipToday(user); }
    @PostMapping("/today/depth/{depth}") public TodayResponse depth(@AuthenticationPrincipal User user,@PathVariable JournalDepth depth){return service.switchDepth(user,depth);}

    @GetMapping("/entries")
    public PageResponse<EntryResponse> entries(@AuthenticationPrincipal User user,
            @RequestParam(defaultValue = "") String q, @RequestParam(required = false) JournalOrigin origin,
            @RequestParam(required=false) JournalMood mood,@RequestParam(defaultValue="") String tag,
            @RequestParam(required=false) java.time.LocalDate from,@RequestParam(required=false) java.time.LocalDate to,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return service.list(user, q, origin,mood,tag,from,to, page, size);
    }
    @PostMapping("/entries") @ResponseStatus(HttpStatus.CREATED)
    public EntryResponse create(@AuthenticationPrincipal User user, @Valid @RequestBody EntryRequest request) { return service.create(user, request); }
    @GetMapping("/entries/{id}") public EntryResponse get(@AuthenticationPrincipal User user, @PathVariable String id) { return service.get(user, id); }
    @PutMapping("/entries/{id}") public EntryResponse update(@AuthenticationPrincipal User user, @PathVariable String id, @Valid @RequestBody EntryRequest request) { return service.update(user, id, request); }
    @DeleteMapping("/entries/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal User user, @PathVariable String id) { service.delete(user, id); }

    @GetMapping("/prompts")
    public PageResponse<PromptResponse> prompts(@RequestParam(defaultValue = "") String q,
            @RequestParam(required = false) JournalCategory category, @RequestParam(required = false) JournalDepth depth,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return service.promptLibrary(q, category, depth, page, size);
    }
    @GetMapping("/settings") public ReminderSettingsResponse settings(@AuthenticationPrincipal User user) { return service.getSettings(user); }
    @PutMapping("/settings") public ReminderSettingsResponse settings(@AuthenticationPrincipal User user, @Valid @RequestBody ReminderSettingsRequest request) { return service.updateSettings(user, request); }
    @GetMapping("/on-this-day") public List<EntryResponse> onThisDay(@AuthenticationPrincipal User user){return service.onThisDay(user);}
    @GetMapping("/stats") public JournalStatsResponse stats(@AuthenticationPrincipal User user,@RequestParam YearMonth month){return service.stats(user,month);}
    @GetMapping("/tags") public List<String> tags(@AuthenticationPrincipal User user){return service.tagNames(user);}
    @GetMapping("/packs") public List<PackResponse> packs(@AuthenticationPrincipal User user){return service.packList(user);}
    @PutMapping("/packs/{id}/follow") public PackResponse follow(@AuthenticationPrincipal User user,@PathVariable String id){return service.followPack(user,id,true);}
    @DeleteMapping("/packs/{id}/follow") public PackResponse unfollow(@AuthenticationPrincipal User user,@PathVariable String id){return service.followPack(user,id,false);}
    @PostMapping("/ai/follow-up") public AiFollowUpResponse followUp(@AuthenticationPrincipal User user,@Valid @RequestBody AiFollowUpRequest request){return service.aiFollowUp(user,request);}
    @GetMapping("/ai/personalized-prompt") public AiFollowUpResponse personalized(@AuthenticationPrincipal User user){return service.personalizedPrompt(user);}
    @PutMapping("/lock/pin") public ReminderSettingsResponse setPin(@AuthenticationPrincipal User user,@Valid @RequestBody PinRequest request){return service.setPin(user,request.pin());}
    @DeleteMapping("/lock/pin") public ReminderSettingsResponse disablePin(@AuthenticationPrincipal User user,@Valid @RequestBody PinRequest request){return service.disablePin(user,request.pin());}
    @PostMapping("/lock/unlock") public UnlockResponse unlock(@AuthenticationPrincipal User user,@Valid @RequestBody PinRequest request){return service.unlock(user,request.pin());}
    @GetMapping("/lock/status") public ReminderSettingsResponse lockStatus(@AuthenticationPrincipal User user){return service.getSettings(user);}
    @GetMapping("/export/markdown") public ResponseEntity<byte[]> export(@AuthenticationPrincipal User user){byte[] data=service.exportMarkdown(user).getBytes(StandardCharsets.UTF_8);return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=fittrack-journal.md").header(HttpHeaders.CONTENT_TYPE,"text/markdown; charset=UTF-8").body(data);}
    @GetMapping(value="/export/print",produces=MediaType.TEXT_HTML_VALUE) public ResponseEntity<byte[]> exportPrint(@AuthenticationPrincipal User user){byte[] data=service.exportHtml(user).getBytes(StandardCharsets.UTF_8);return ResponseEntity.ok().header(HttpHeaders.CONTENT_TYPE,"text/html; charset=UTF-8").body(data);}
}
