CREATE TABLE journal_prompt_packs (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(500),
    icon VARCHAR(20),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE journal_prompts ADD COLUMN pack_id VARCHAR(255) REFERENCES journal_prompt_packs(id);
CREATE INDEX idx_journal_prompts_pack ON journal_prompts(pack_id, active);

CREATE TABLE journal_pack_follows (
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pack_id VARCHAR(255) NOT NULL REFERENCES journal_prompt_packs(id) ON DELETE CASCADE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, pack_id)
);

CREATE TABLE journal_tags (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_journal_tag_owner_name UNIQUE(user_id, name)
);

CREATE TABLE journal_entry_tag_links (
    entry_id VARCHAR(255) NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    tag_id VARCHAR(255) NOT NULL REFERENCES journal_tags(id) ON DELETE CASCADE,
    PRIMARY KEY(entry_id, tag_id)
);

CREATE TABLE journal_entry_images (
    id VARCHAR(255) PRIMARY KEY,
    entry_id VARCHAR(255) NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_journal_images_entry ON journal_entry_images(entry_id, sort_order);

ALTER TABLE journal_settings
    ADD COLUMN personalized_prompts_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN ai_follow_up_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN lock_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN pin_hash VARCHAR(255);

CREATE TABLE journal_unlock_sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP(6) NOT NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_journal_unlock_owner_expiry ON journal_unlock_sessions(user_id, expires_at);

INSERT INTO journal_prompt_packs(id,name,description,icon,active,sort_order) VALUES
('journal-pack-self','Hiểu mình hơn','Những câu hỏi giúp bạn quan sát bản thân rõ hơn.','🌱',TRUE,1),
('journal-pack-mind','Những điều trong đầu','Gỡ rối suy nghĩ và cảm xúc trong ngày.','🧠',TRUE,2),
('journal-pack-night','Trước khi ngủ','Khép lại ngày bằng vài dòng nhẹ nhàng.','🌙',TRUE,3),
('journal-pack-memory','Ký ức','Gợi lại con người, nơi chốn và khoảnh khắc cũ.','🕰',TRUE,4),
('journal-pack-imagination','Tưởng tượng','Mở một cánh cửa cho sự sáng tạo.','🎨',TRUE,5),
('journal-pack-relationship','Những mối quan hệ','Nhìn lại cách bạn kết nối với mọi người.','❤️',TRUE,6),
('journal-pack-future','Tương lai','Viết cho những ngày phía trước.','🔭',TRUE,7),
('journal-pack-quirky','Những câu hỏi kỳ quặc','Nhẹ nhàng, bất ngờ và không quá nghiêm túc.','🎲',TRUE,8);

UPDATE journal_prompts SET pack_id = CASE category
    WHEN 'OBSERVATION' THEN 'journal-pack-night'
    WHEN 'SELF' THEN 'journal-pack-self'
    WHEN 'MEMORY' THEN 'journal-pack-memory'
    WHEN 'IMAGINATION' THEN 'journal-pack-imagination'
    WHEN 'REFLECTION' THEN 'journal-pack-mind'
    WHEN 'RELATIONSHIP' THEN 'journal-pack-relationship'
    WHEN 'FUTURE' THEN 'journal-pack-future'
    WHEN 'QUIRKY' THEN 'journal-pack-quirky'
END;
