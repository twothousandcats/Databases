USE
news_bd;

-- 1. todo: Извлечь все опубликованные новости
SELECT id,
       title,
       priority,
       is_pinned,
       created_at,
       updated_at
FROM news
WHERE is_draft = 0
ORDER BY created_at DESC;

-- 2. todo: Извлечь информацию о миниатюре конкретной новости по идентификатору новости
SELECT media_asset.file_name, media_asset.mime_type, media_asset.storage_path, media_asset.file_size_bytes
FROM news
         JOIN news_block ON news.id = news_block.news_id
         JOIN block_content ON news_block.content_id = block_content.id
         JOIN media_asset ON block_content.media_asset_id = media_asset.id
WHERE news.id = 1
  AND block_content.type = 'image'
ORDER BY news_block.sort_order LIMIT 1;

-- 3. todo: Извлеките все ip адреса, с которых были просмотры.
SELECT DISTINCT ip_address
FROM news_view;

-- 4 todo: Извлечь информацию для отображения конкретной новости целиком в портале пользователя (информацию, которая доступна всем пользователям)
-- todo:
-- рассказать какие есть виды JOIN, как работает
--     "INNER" JOIN - совпадение в обеих таблицах
--     LEFT "OUTER" JOIN - все строки из левой таблицы, и совпадения из правой
--     RIGHT "OUTER" JOIN - -//-
--     FULL "OUTER" JOIN - все строки из обеих таблиц. Там где нет совпадений по предикату - null
--     CROSS JOIN - декартово произведение таблицы. Условий нет
--     SELF JOIN - соединение
-- рассказать про GROUP BY
-- вывести новость целиком и блоками
-- порядок выполнения FROM - LIMIT

-- Новость + авторы + счётчик просмотров
SELECT news.id                                                            AS news_id,
       news.title,
       news.is_pinned,
       news.priority,
       news.created_at,
       news.updated_at,
       author_profile.id                                                  AS author_id,
       author_profile.full_name,
       author_profile.avatar_url,
       author_profile.twitter_handle,
       author_profile.is_verified,
       news_author_link.role                                              AS author_role,
       news_author_link.order_index,
       (SELECT COUNT(*) FROM news_view WHERE news_view.news_id = news.id) AS view_count
FROM news
         JOIN news_author_link ON news_author_link.news_id = news.id
         JOIN author_profile ON author_profile.id = news_author_link.author_id
WHERE news.id = 4
  AND news.is_draft = 0
ORDER BY news_author_link.order_index;

-- Блоки контента
SELECT news_block.sort_order,
       block_content.type       AS block_type,
       block_content.data,
       media_asset.storage_path AS media_url,
       media_asset.mime_type,
       media_asset.file_name    AS media_file_name
FROM news_block
         JOIN block_content ON block_content.id = news_block.content_id
         LEFT JOIN media_asset ON media_asset.id = block_content.media_asset_id
WHERE news_block.news_id = 4
ORDER BY news_block.sort_order;

-- Публичные комментарии
SELECT comment.id,
       comment.parent_comment_id,
       comment.content,
       comment.likes_count,
       comment.created_at
FROM comment
WHERE comment.news_id = 4
  AND comment.is_deleted = 0
ORDER BY COALESCE(comment.parent_comment_id, comment.id),
         comment.parent_comment_id IS NOT NULL,
         comment.created_at;

-- 5 todo: Извлечь ТОП 5 самых просматриваемых новостей
SELECT news.id, news.title, COUNT(news_view.id) AS view_count
FROM news
         JOIN news_view ON news.id = news_view.news_id
GROUP BY news.id, news.title
ORDER BY view_count DESC LIMIT 5;

-- 6 todo: Извлечь все новости, которые просматривали после конкретной даты (дату придумаете сами)
SELECT DISTINCT news.id, news.title
FROM news
         JOIN news_view ON news.id = news_view.news_id
WHERE news_view.viewed_at > '2026-04-01 00:00:00';

-- 7 todo: Найти новости с наибольшим количеством блоков контента
SELECT news.id, news.title, COUNT(news_block.id) AS block_count
FROM news
         JOIN news_block ON news.id = news_block.news_id
GROUP BY news.id, news.title
ORDER BY block_count DESC LIMIT 1;

-- 8 todo: Извлечь ТОП 5 самых комментируемых новостей
SELECT news.id, news.title, COUNT(comment.id) AS comment_count
FROM news
         JOIN comment ON news.id = comment.news_id
GROUP BY news.id, news.title
ORDER BY comment_count DESC LIMIT 5;

-- 9 todo: Извлечь даты, в которые новости (учитывать все новости) просматривались наиболее часто
SELECT DATE(viewed_at) AS view_date, COUNT(*) AS total_views
FROM news_view
GROUP BY view_date
ORDER BY total_views DESC
    LIMIT 10;

-- 12 todo: Придумать запрос с новыми сущностями с использованием HAVING
-- todo: разница между HAVING и WHERE
SELECT author_profile.id, author_profile.full_name, COUNT(news_author_link.news_id) AS published_news_count
FROM author_profile
         JOIN news_author_link ON author_profile.id = news_author_link.author_id
         JOIN news ON news_author_link.news_id = news.id
WHERE news.is_draft = 0
GROUP BY author_profile.id, author_profile.full_name
HAVING published_news_count > 1
ORDER BY published_news_count DESC LIMIT 2;