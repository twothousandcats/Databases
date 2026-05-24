-- Таблица
CREATE TABLE users
(
    id      INT AUTO_INCREMENT PRIMARY KEY,
    profile JSON NOT NULL,
    login   VARCHAR(100) AS (JSON_UNQUOTE(JSON_EXTRACT(profile, '$.login'))) STORED NOT NULL,
    CHECK (
        JSON_CONTAINS_PATH(profile, 'all', '$.first_name', '$.last_name', '$.login')
        )
);

-- Добавить пользователя
INSERT INTO users (profile)
VALUES (JSON_OBJECT(
        'first_name', 'Ivan',
        'last_name', 'Petrov',
        'login', 'ivan_p',
        'age', 30,
        'city', 'Moscow'
        ));

-- Извлечь last_name у группы пользователей
SELECT id, profile ->>'$.last_name' AS last_name
FROM users
WHERE id IN (1, 2, 3);

-- Обновить first_name у группы пользователей
UPDATE users
SET profile = JSON_SET(profile, '$.first_name', 'NewName')
WHERE id IN (1, 2, 3);

-- Индекс по login
CREATE INDEX idx_users_login ON users (login);

-- Сохранить массив телефонов
UPDATE users
SET profile = JSON_SET(profile, '$.phones', JSON_ARRAY('+79001112233', '+79004445566', '+79007778899'))
WHERE id = 1;

-- Извлечь последний номер
SELECT JSON_EXTRACT(
               profile,
               CONCAT('$.phones[', JSON_LENGTH(profile, '$.phones') - 1, ']')
       ) AS last_phone
FROM users
WHERE id = 1;

-- Поиск пользователей по номеру в массиве
SELECT id, profile ->>'$.login' AS login
FROM users
WHERE JSON_CONTAINS(profile->'$.phones', JSON_QUOTE('+79001112233'));