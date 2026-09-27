ALTER TABLE users
    ADD COLUMN journal_enabled BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE journal_prompts (
    id VARCHAR(255) PRIMARY KEY,
    content TEXT NOT NULL,
    category VARCHAR(30) NOT NULL,
    depth VARCHAR(20) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL,
    updated_at TIMESTAMP(6) NOT NULL,
    CONSTRAINT chk_journal_prompt_category CHECK (category IN
        ('OBSERVATION','SELF','MEMORY','IMAGINATION','REFLECTION','RELATIONSHIP','FUTURE','QUIRKY')),
    CONSTRAINT chk_journal_prompt_depth CHECK (depth IN ('LIGHT','MEDIUM','DEEP'))
);
CREATE INDEX idx_journal_prompts_active_category ON journal_prompts(active, category, depth);

CREATE TABLE journal_prompt_displays (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prompt_id VARCHAR(255) NOT NULL REFERENCES journal_prompts(id),
    display_date DATE NOT NULL,
    cycle_number INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP(6) NOT NULL,
    answered_at TIMESTAMP(6),
    skipped_at TIMESTAMP(6),
    CONSTRAINT chk_journal_display_cycle CHECK (cycle_number > 0),
    CONSTRAINT chk_journal_display_status CHECK (status IN ('ASSIGNED','ANSWERED','SKIPPED')),
    CONSTRAINT uk_journal_display_cycle UNIQUE (user_id, prompt_id, cycle_number)
);
CREATE INDEX idx_journal_display_user_date ON journal_prompt_displays(user_id, display_date, created_at DESC);

CREATE TABLE journal_entries (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    origin VARCHAR(20) NOT NULL,
    prompt_id VARCHAR(255) REFERENCES journal_prompts(id),
    prompt_display_id VARCHAR(255) UNIQUE REFERENCES journal_prompt_displays(id),
    title VARCHAR(200),
    body TEXT NOT NULL,
    mood VARCHAR(20),
    created_at TIMESTAMP(6) NOT NULL,
    updated_at TIMESTAMP(6) NOT NULL,
    archived_at TIMESTAMP(6),
    CONSTRAINT chk_journal_entry_origin CHECK (origin IN ('PROMPT','FREEFORM')),
    CONSTRAINT chk_journal_entry_mood CHECK (mood IS NULL OR mood IN
        ('VERY_LOW','LOW','NEUTRAL','GOOD','VERY_GOOD')),
    CONSTRAINT chk_journal_entry_prompt CHECK (
        (origin = 'PROMPT' AND prompt_id IS NOT NULL AND prompt_display_id IS NOT NULL)
        OR (origin = 'FREEFORM' AND prompt_id IS NULL AND prompt_display_id IS NULL)
    )
);
CREATE INDEX idx_journal_entries_owner_date ON journal_entries(user_id, entry_date DESC, created_at DESC);
CREATE INDEX idx_journal_entries_owner_active ON journal_entries(user_id, archived_at);

CREATE TABLE journal_settings (
    user_id VARCHAR(255) PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    reminder_time TIME NOT NULL DEFAULT '21:30:00',
    updated_at TIMESTAMP(6) NOT NULL
);

INSERT INTO journal_prompts (id, content, category, depth, active, created_at, updated_at) VALUES
('journal-prompt-001', 'Mở cửa sổ nhìn ra ngoài, điều đầu tiên bạn chú ý thấy là gì?', 'OBSERVATION', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-002', 'Âm thanh nào đang ở gần bạn nhất lúc này?', 'OBSERVATION', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-003', 'Nếu chụp một bức ảnh đại diện cho hôm nay, bạn sẽ chụp gì?', 'OBSERVATION', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-004', 'Có vật gì ở cạnh bạn mà bạn ít khi để ý đến?', 'OBSERVATION', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-005', 'Khoảnh khắc nhỏ nào hôm nay đáng được nhớ lại?', 'OBSERVATION', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-006', 'Nếu tâm trạng hôm nay có một màu, đó là màu gì?', 'SELF', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-007', 'Điều gì đang chiếm nhiều chỗ nhất trong đầu bạn?', 'SELF', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-008', 'Gần đây có điều gì về bản thân khiến bạn bất ngờ?', 'SELF', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-009', 'Cơ thể bạn đang muốn nói điều gì với bạn lúc này?', 'SELF', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-010', 'Bạn cần thêm điều gì và bớt điều gì trong tuần này?', 'SELF', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-011', 'Giấc mơ kỳ lạ nhất bạn còn nhớ là gì?', 'MEMORY', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-012', 'Mùi hương nào khiến bạn nhớ về tuổi thơ?', 'MEMORY', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-013', 'Có ngày bình thường nào trong quá khứ mà bạn muốn sống lại không?', 'MEMORY', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-014', 'Một lời động viên cũ nào vẫn còn ở lại với bạn?', 'MEMORY', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-015', 'Kỷ niệm nào khiến bạn mỉm cười mỗi khi vô tình nhớ tới?', 'MEMORY', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-016', 'Nếu căn phòng của bạn có thể nói, nó sẽ kể gì về bạn?', 'IMAGINATION', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-017', 'Nếu gửi một tin nhắn cho chính mình của mười năm trước, bạn sẽ viết gì?', 'IMAGINATION', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-018', 'Nếu cuộc đời hiện tại là một chương sách, chương này có tên gì?', 'IMAGINATION', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-019', 'Nếu cảm xúc hôm nay là một sinh vật, nó trông như thế nào?', 'IMAGINATION', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-020', 'Nếu ngày mai thức dậy ở một nơi hoàn toàn khác, bạn muốn đó là đâu?', 'IMAGINATION', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-021', 'Có điều gì bạn đang cố kiểm soát dù thực ra không thể?', 'REFLECTION', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-022', 'Gần đây bạn nói “không sao” với chuyện gì mà thật ra nó có sao?', 'REFLECTION', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-023', 'Điều gì từng rất quan trọng nhưng bây giờ không còn như vậy?', 'REFLECTION', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-024', 'Nếu bỏ qua tiền bạc và kỳ vọng của người khác, bạn muốn dành thời gian cho điều gì?', 'REFLECTION', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-025', 'Một quyết định gần đây đã dạy bạn điều gì?', 'REFLECTION', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-026', 'Ai đã làm ngày hôm nay của bạn dễ chịu hơn một chút?', 'RELATIONSHIP', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-027', 'Có điều gì bạn muốn nói với một người nhưng vẫn chưa nói?', 'RELATIONSHIP', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-028', 'Mối quan hệ nào đang cho bạn nhiều năng lượng nhất?', 'RELATIONSHIP', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-029', 'Bạn cảm thấy được lắng nghe nhất khi ở cạnh ai?', 'RELATIONSHIP', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-030', 'Bạn muốn cảm ơn ai vì một điều rất nhỏ?', 'RELATIONSHIP', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-031', 'Một năm nữa, bạn muốn cảm ơn bản thân hôm nay vì điều gì?', 'FUTURE', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-032', 'Điều gì bạn muốn học trước khi năm nay kết thúc?', 'FUTURE', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-033', 'Phiên bản bình tĩnh hơn của bạn sẽ xử lý chuyện hiện tại thế nào?', 'FUTURE', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-034', 'Một thay đổi nhỏ nào có thể làm tuần tới tốt hơn?', 'FUTURE', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-035', 'Bạn muốn cuộc sống thường ngày của mình trông thế nào sau ba năm?', 'FUTURE', 'DEEP', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-036', 'Nếu suy nghĩ hôm nay là thời tiết, trời đang thế nào?', 'QUIRKY', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-037', 'Nếu nỗi buồn có mùi, bạn nghĩ nó có mùi gì?', 'QUIRKY', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-038', 'Nếu giấc mơ đêm qua là trailer phim, nó thuộc thể loại gì?', 'QUIRKY', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-039', 'Nếu bạn có các thanh trạng thái giống game, thanh nào đang thấp nhất?', 'QUIRKY', 'MEDIUM', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('journal-prompt-040', 'Nếu não có lịch sử tìm kiếm riêng, dòng gần nhất của bạn là gì?', 'QUIRKY', 'LIGHT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
