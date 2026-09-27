-- Expand the curated seed library to 320 prompts without using AI at runtime.
-- Each of the original 40 editorial prompts receives seven distinct reflection
-- lenses. The original prompt remains available as the shortest version.
INSERT INTO journal_prompts (
    id, content, category, depth, active, created_at, updated_at, pack_id
)
SELECT
    p.id || '-lens-' || lens.code,
    p.content || ' ' || lens.suffix,
    p.category,
    CASE
        WHEN lens.code IN ('today', 'small') THEN 'LIGHT'
        WHEN lens.code IN ('week', 'person', 'place') THEN 'MEDIUM'
        ELSE 'DEEP'
    END,
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    p.pack_id
FROM journal_prompts p
CROSS JOIN (VALUES
    ('today', 'Hãy nghĩ về một khoảnh khắc trong hôm nay.'),
    ('week', 'Hãy nhìn lại bảy ngày gần đây.'),
    ('small', 'Chỉ cần kể lại một chi tiết rất nhỏ.'),
    ('person', 'Một người nào đã ảnh hưởng đến câu trả lời của bạn?'),
    ('place', 'Một nơi chốn nào xuất hiện đầu tiên trong suy nghĩ của bạn?'),
    ('lesson', 'Điều này đang giúp bạn hiểu thêm điều gì về chính mình?'),
    ('future', 'Bạn muốn nhớ điều gì từ câu trả lời này sau một năm nữa?')
) AS lens(code, suffix)
WHERE p.id LIKE 'journal-prompt-___'
ON CONFLICT (id) DO NOTHING;
