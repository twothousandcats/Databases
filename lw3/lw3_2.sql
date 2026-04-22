-- вставки
INSERT IGNORE INTO author_profile (id, full_name, bio, avatar_url, twitter_handle, joined_date, is_verified, email)
VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Ivan Petrov', 'Tech journalist', 'https://example.com/ivan.jpg', '@ivan_tech', '2023-01-15', 1, 'ivan@example.com');

INSERT IGNORE INTO media_asset (id, user_id, file_name, mime_type, file_size_bytes, storage_path, checksum_sha256)
VALUES ('m1n2o3p4-q5r6-7890-stuv-wx1234567890', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'article_img.png', 'image/png', 102400, '/uploads/2023/img.png', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');

INSERT IGNORE INTO author_profile (id, full_name, bio, joined_date, email)
VALUES ('b2c3d4e5-f6g7-8901-bcde-fg2345678901', 'Anna Smirnova', 'Editor', '2023-02-20', 'anna@example.com');

-- обновы
-- todo: объяснить почему обновляет, а не создает при изменении идентификатора
-- id - primary key, email - unique index
INSERT INTO author_profile (id, full_name, bio, joined_date, is_verified, email)
VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Ivan Petrov Updated', 'Senior Tech Journalist', '2023-01-15', 1, 'ivan@example.com')
    ON DUPLICATE KEY UPDATE full_name = VALUES(full_name), bio = VALUES(bio), updated_at = NOW();

-- Обновление новости
INSERT INTO news (title, is_draft, priority, is_pinned)
VALUES ('Breaking News: C++20', 1, 10, 0)
    ON DUPLICATE KEY UPDATE priority = VALUES(priority), is_pinned = 1;

-- Связь автора и новости
INSERT INTO news_author_link (news_id, author_id, role, contribution_percent, order_index)
VALUES (1, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'main', 100, 0)
    ON DUPLICATE KEY UPDATE role = VALUES(role), contribution_percent = VALUES(contribution_percent);

-- коммит 1
START TRANSACTION;
INSERT INTO news (title, is_draft, priority) VALUES ('Transaction News 1', 1, 5);
SET @new_news_id = LAST_INSERT_ID();

INSERT INTO block_content (`type`, `data`) VALUES ('text', 'Initial content for transaction test.');
SET @content_id = LAST_INSERT_ID();

INSERT INTO news_block (news_id, sort_order, content_id) VALUES (@new_news_id, 1, @content_id);
-- Проверка перед коммитом
SELECT COUNT(*) FROM news_block WHERE news_id = @new_news_id;
COMMIT;

-- ролбек 1
START TRANSACTION;
INSERT INTO news (title, is_draft, priority) VALUES ('Rollback News Test', 1, 0);
SET @rb_news_id = LAST_INSERT_ID();
-- Вставка комментария с невалидными данными или проверка бизнес-логики не прошла
INSERT INTO comment (news_id, content, ip_address) VALUES (@rb_news_id, 'Spam content to be rolled back', '127.0.0.1');
ROLLBACK;

-- коммит 2 (обновление просмотров)
START TRANSACTION;
INSERT INTO news_view (id, news_id, ip_address) VALUES ('v1111111-1111-1111-1111-111111111111', 1, '192.168.1.1');
INSERT INTO news_view (id, news_id, ip_address) VALUES ('v2222222-2222-2222-2222-222222222222', 1, '192.168.1.2');
SELECT COUNT(*) FROM news_view WHERE news_id = 1;
COMMIT;

-- ролбек 2 (случайный checksum)
START TRANSACTION;
INSERT INTO media_asset (id, user_id, file_name, mime_type, file_size_bytes, storage_path, checksum_sha256)
VALUES ('temp-id-1', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'bad_file.jpg', 'image/jpeg', 0, '/tmp/bad', '0000000000000000000000000000000000000000000000000000000000000000');
ROLLBACK;

-- коммит 3
START TRANSACTION;
INSERT INTO news_author_link (news_id, author_id, role, order_index)
VALUES (1, 'b2c3d4e5-f6g7-8901-bcde-fg2345678901', 'co-author', 1)
    ON DUPLICATE KEY UPDATE role='co-author';
COMMIT;

-- откат по длине заголовка
START TRANSACTION;
UPDATE news_draft SET title = 'Invalid Title Length Exceeding Limits Possibly...' WHERE news_id = 1;
ROLLBACK;

-- author_profile
UPDATE author_profile SET is_verified = 1, twitter_handle = '@ivan_official' WHERE email = 'ivan@example.com';
UPDATE author_profile SET bio = 'Updated bio text after verification.' WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- media_asset
UPDATE media_asset SET file_name = 'article_img_v2.png' WHERE id = 'm1n2o3p4-q5r6-7890-stuv-wx1234567890';
UPDATE media_asset SET storage_path = '/uploads/2024/img.png' WHERE id = 'm1n2o3p4-q5r6-7890-stuv-wx1234567890';

-- block_content
UPDATE block_content SET data = 'Updated text content.' WHERE id = 1;
UPDATE block_content SET `type` = 'text' WHERE id = 1; -- Пример смены типа или подтверждения

-- news
UPDATE news SET is_draft = 0, priority = 100 WHERE id = 1;
UPDATE news SET is_pinned = 1 WHERE id = 1;

-- comment
UPDATE comment SET likes_count = 5 WHERE id = 1;
UPDATE comment SET is_deleted = 0 WHERE id = 1;

-- news_author_link
UPDATE news_author_link SET contribution_percent = 80 WHERE news_id = 1 AND author_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
UPDATE news_author_link SET approved_at = NOW() WHERE news_id = 1 AND author_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- ОБРАТНЫЕ
UPDATE author_profile SET is_verified = 1, twitter_handle = '@ivan_tech' WHERE email = 'ivan@example.com';
UPDATE author_profile SET bio = 'Senior Tech Journalist' WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

UPDATE media_asset SET file_name = 'article_img.png' WHERE id = 'm1n2o3p4-q5r6-7890-stuv-wx1234567890';
UPDATE media_asset SET storage_path = '/uploads/2023/img.png' WHERE id = 'm1n2o3p4-q5r6-7890-stuv-wx1234567890';

UPDATE block_content SET data = 'Initial content for transaction test.' WHERE id = 1;

UPDATE news SET is_draft = 1, priority = 10 WHERE id = 1;
UPDATE news SET is_pinned = 0 WHERE id = 1;

UPDATE comment SET likes_count = 0 WHERE id = 1;
UPDATE comment SET is_deleted = 0 WHERE id = 1;

UPDATE news_author_link SET contribution_percent = 100 WHERE news_id = 1 AND author_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
UPDATE news_author_link SET approved_at = NULL WHERE news_id = 1 AND author_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';