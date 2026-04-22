-- todo: UUID - из приложения
-- todo: надо ли явно индексировать внешние?
CREATE DATABASE IF NOT EXISTS courses_db;

USE courses_db;

-- Пользователи
-- Статус: активен, неактивен, уволен
-- deleted_at — soft delete
CREATE TABLE IF NOT EXISTS user
(
    id         CHAR(36)                             NOT NULL,
    name       VARCHAR(255)                         NULL,
    email      VARCHAR(255)                         NOT NULL,
    state      ENUM ('active', 'inactive', 'fired') NOT NULL DEFAULT 'active',
    created_at DATETIME                             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME                             NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME                             NULL,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_user_email (email ASC)
) ENGINE = InnoDB;

-- Курс
-- course_type — связь, с сущностями video / audio / quiz
CREATE TABLE IF NOT EXISTS course
(
    id          CHAR(36)                        NOT NULL,
    name        VARCHAR(255)                    NOT NULL,
    description TEXT                            NULL,
    course_type ENUM ('video', 'audio', 'quiz') NOT NULL,
    created_at  DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at  DATETIME                        NULL,
    PRIMARY KEY (id),
    INDEX idx_course_type (course_type ASC)
) ENGINE = InnoDB;

-- Видео-курс
CREATE TABLE IF NOT EXISTS video
(
    course_id  CHAR(36)                                  NOT NULL,
    source_url VARCHAR(500)                              NOT NULL,
    duration   INT UNSIGNED                              NOT NULL, -- сек
    format     ENUM ('mp4', 'webm', 'mov', 'avi', 'mkv') NOT NULL,
    size       BIGINT UNSIGNED                           NOT NULL, -- байт
    created_at DATETIME                                  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME                                  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (course_id),
    CONSTRAINT fk_video_course
        FOREIGN KEY (course_id)
            REFERENCES course (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- Аудио-курс
CREATE TABLE IF NOT EXISTS audio
(
    course_id  CHAR(36)     NOT NULL,
    source_url VARCHAR(500) NOT NULL,
    duration   INT UNSIGNED NOT NULL COMMENT 'в секундах',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (course_id),
    CONSTRAINT fk_audio_course
        FOREIGN KEY (course_id)
            REFERENCES course (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- Квиз
-- Статус: загружен / обработан / готов к использованию
-- available_duration - время на прохождение
-- weight - цена за прохождение
CREATE TABLE IF NOT EXISTS quiz
(
    course_id          CHAR(36)                                NOT NULL,
    source_url         VARCHAR(500)                            NULL,
    weight             DECIMAL(5, 2)                           NULL,
    available_duration INT UNSIGNED                            NULL, -- сек
    state              ENUM ('uploaded', 'processed', 'ready') NOT NULL DEFAULT 'uploaded',
    created_at         DATETIME                                NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME                                NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (course_id),
    CONSTRAINT fk_quiz_course
        FOREIGN KEY (course_id)
            REFERENCES course (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- Шкала оценок конкретного квиза
-- для quiz X оценка 5 ставится за 85-100 баллов
-- Пересечение диапазонов проверяется на уровне приложения
CREATE TABLE IF NOT EXISTS quiz_mark
(
    id         CHAR(36)         NOT NULL,
    quiz_id    CHAR(36)         NOT NULL,
    mark       TINYINT UNSIGNED NOT NULL,
    min_score  TINYINT UNSIGNED NOT NULL,
    max_score  TINYINT UNSIGNED NOT NULL,
    created_at DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_quiz_mark (quiz_id ASC, mark ASC),
    INDEX idx_quiz_mark_range (quiz_id ASC, min_score ASC, max_score ASC),
    CONSTRAINT fk_quiz_mark_quiz
        FOREIGN KEY (quiz_id)
            REFERENCES quiz (course_id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT ck_quiz_mark_value CHECK (mark BETWEEN 2 AND 5),
    CONSTRAINT ck_quiz_mark_range CHECK (min_score <= max_score),
    CONSTRAINT ck_quiz_mark_min CHECK (min_score <= 100),
    CONSTRAINT ck_quiz_mark_max CHECK (max_score <= 100)
) ENGINE = InnoDB;

-- Вопросы квиза
CREATE TABLE IF NOT EXISTS quiz_question
(
    id          CHAR(36)                             NOT NULL,
    quiz_id     CHAR(36)                             NOT NULL,
    text        TEXT                                 NOT NULL,
    type        ENUM ('multiple_choice', 'sequence') NOT NULL,
    picture_url VARCHAR(500)                         NULL,
    position    INT UNSIGNED                         NOT NULL DEFAULT 0,
    created_at  DATETIME                             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME                             NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_quiz_question_position (quiz_id ASC, position ASC),
    /* INDEX idx_quiz_question_quiz (quiz_id ASC), */
    CONSTRAINT fk_quiz_question_quiz
        FOREIGN KEY (quiz_id)
            REFERENCES quiz (course_id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- Варианты ответа: множественный выбор
CREATE TABLE IF NOT EXISTS multiple_choice_question_available_values
(
    id          CHAR(36)     NOT NULL,
    question_id CHAR(36)     NOT NULL,
    value       VARCHAR(500) NOT NULL,
    is_correct  TINYINT(1)   NOT NULL DEFAULT 0,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    /* INDEX idx_mc_values_question (question_id ASC), */
    CONSTRAINT fk_mc_values_question
        FOREIGN KEY (question_id)
            REFERENCES quiz_question (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT ck_mc_values_is_correct CHECK (is_correct IN (0, 1))
) ENGINE = InnoDB;

-- Варианты ответа: последовательность
-- порядок — связный список через next_value_id
-- последний next_value_id: NULL.
CREATE TABLE IF NOT EXISTS sequence_question_available_values
(
    id            CHAR(36)     NOT NULL,
    question_id   CHAR(36)     NOT NULL,
    value         VARCHAR(500) NOT NULL,
    next_value_id CHAR(36)     NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    /* INDEX idx_seq_values_question (question_id ASC),
    INDEX idx_seq_values_next (next_value_id ASC), */
    CONSTRAINT fk_seq_values_question
        FOREIGN KEY (question_id)
            REFERENCES quiz_question (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT fk_seq_values_next
        FOREIGN KEY (next_value_id)
            REFERENCES sequence_question_available_values (id)
            ON DELETE SET NULL
            ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- Назначение пользователя на курс
CREATE TABLE IF NOT EXISTS enrollment
(
    id         CHAR(36) NOT NULL,
    user_id    CHAR(36) NOT NULL,
    course_id  CHAR(36) NOT NULL,
    start_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_date   DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_enrollment_user_course (user_id ASC, course_id ASC),
    /* INDEX idx_enrollment_user (user_id ASC),
    INDEX idx_enrollment_course (course_id ASC), */
    CONSTRAINT fk_enrollment_user
        FOREIGN KEY (user_id)
            REFERENCES user (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id)
            REFERENCES course (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- Попытка прохождения
-- score — итоговый балл
-- квиз - 0 .. 100
-- видео/аудио - % просмотра/прослушивания
-- duration — длительность попытки в секундах.
CREATE TABLE IF NOT EXISTS attempt
(
    id            CHAR(36)         NOT NULL,
    enrollment_id CHAR(36)         NOT NULL,
    start_date    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_date      DATETIME         NULL,
    score         TINYINT UNSIGNED NULL,
    duration      INT UNSIGNED     NULL,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    /* INDEX idx_attempt_enrollment (enrollment_id ASC), */
    CONSTRAINT fk_attempt_enrollment
        FOREIGN KEY (enrollment_id)
            REFERENCES enrollment (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT ck_attempt_score CHECK (score IS NULL OR score <= 100)
) ENGINE = InnoDB;


-- Ответ на вопрос в рамках попытки
-- value — JSON-массив UUID выбранных вариантов:
--   1) multiple_choice — порядок неважен: ["uuid1", "uuid2"]
--   2) sequence — порядок = ответ пользователя: ["uuid3", "uuid1", "uuid2"]
--
-- mc_value_id / seq_value_id — опциональная ссылка на первый выбранный вариант для ссылочной целостности
-- Из двух полей заполнено ровно одно (в зависимости от типа вопроса)
-- уникальность будет обеспечиваться на уровне исполнения приложения
CREATE TABLE IF NOT EXISTS quiz_attempt_answer
(
    id           CHAR(36) NOT NULL,
    attempt_id   CHAR(36) NOT NULL,
    question_id  CHAR(36) NOT NULL,
    value        JSON     NOT NULL,
    mc_value_id  CHAR(36) NULL,
    seq_value_id CHAR(36) NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_answer_attempt_question (attempt_id ASC, question_id ASC),
    /* INDEX idx_answer_attempt (attempt_id ASC),
    INDEX idx_answer_question (question_id ASC),
    INDEX idx_answer_mc_value (mc_value_id ASC),
    INDEX idx_answer_seq_value (seq_value_id ASC), */
    CONSTRAINT fk_answer_attempt
        FOREIGN KEY (attempt_id)
            REFERENCES attempt (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT fk_answer_question
        FOREIGN KEY (question_id)
            REFERENCES quiz_question (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
    CONSTRAINT fk_answer_mc_value
        FOREIGN KEY (mc_value_id)
            REFERENCES multiple_choice_question_available_values (id)
            ON DELETE SET NULL
            ON UPDATE NO ACTION,
    CONSTRAINT fk_answer_seq_value
        FOREIGN KEY (seq_value_id)
            REFERENCES sequence_question_available_values (id)
            ON DELETE SET NULL
            ON UPDATE NO ACTION
) ENGINE = InnoDB;

-- Тестовые данные
-- Пользователи
INSERT INTO user (id, name, email, state)
    VALUES ('11111111-1111-1111-1111-000000000001', 'Анна Иванова', 'anna@example.com', 'active'),
           ('11111111-1111-1111-1111-000000000002', 'Борис Петров', 'boris@example.com', 'active'),
           ('11111111-1111-1111-1111-000000000003', NULL, 'guest@example.com', 'active'),
           ('11111111-1111-1111-1111-000000000004', 'Дмитрий Сидоров', 'dmitry@example.com', 'inactive'),
           ('11111111-1111-1111-1111-000000000005', 'Елена Козлова', 'elena@example.com', 'fired') AS new
ON DUPLICATE KEY UPDATE name  = new.name,
                        email = new.email,
                        state = new.state;
UPDATE user
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = '11111111-1111-1111-1111-000000000005';

-- Курсы
INSERT INTO course (id, name, description, course_type)
    VALUES ('22222222-2222-2222-2222-000000000001', 'Введение в Python', 'Основы языка Python для новичков', 'video'),
           ('22222222-2222-2222-2222-000000000002', 'Подкаст: история алгоритмов',
            'Обзорный подкаст по классическим алгоритмам', 'audio'),
           ('22222222-2222-2222-2222-000000000003', 'Проверка знаний: SQL', 'Квиз по основам SQL', 'quiz'),
           ('22222222-2222-2222-2222-000000000004', 'Проверка знаний: сети', 'Квиз по компьютерным сетям',
            'quiz') AS new
ON DUPLICATE KEY UPDATE name        = new.name,
                        description = new.description,
                        course_type = new.course_type;
INSERT INTO video (course_id, source_url, duration, format, size)
    VALUES ('22222222-2222-2222-2222-000000000001', 'https://cdn.example.com/python-intro.mp4', 3600, 'mp4',
            524288000) AS new
ON DUPLICATE KEY UPDATE source_url = new.source_url,
                        duration   = new.duration,
                        format     = new.format,
                        size       = new.size;
INSERT INTO audio (course_id, source_url, duration)
    VALUES ('22222222-2222-2222-2222-000000000002', 'https://cdn.example.com/algo-podcast.mp3', 2700) AS new
ON DUPLICATE KEY UPDATE source_url = new.source_url,
                        duration   = new.duration;
INSERT INTO quiz (course_id, source_url, weight, available_duration, state)
    VALUES ('22222222-2222-2222-2222-000000000003', 'https://cdn.example.com/sql-quiz.json', 1.00, 1800, 'ready'),
           ('22222222-2222-2222-2222-000000000004', 'https://cdn.example.com/network-quiz.json', 0.50, 1200,
            'processed') AS new
ON DUPLICATE KEY UPDATE source_url         = new.source_url,
                        weight             = new.weight,
                        available_duration = new.available_duration,
                        state              = new.state;

-- Шкала оценок
INSERT INTO quiz_mark (id, quiz_id, mark, min_score, max_score)
    VALUES ('33333333-3333-3333-3333-000000000001', '22222222-2222-2222-2222-000000000003', 2, 0, 49),
           ('33333333-3333-3333-3333-000000000002', '22222222-2222-2222-2222-000000000003', 3, 50, 69),
           ('33333333-3333-3333-3333-000000000003', '22222222-2222-2222-2222-000000000003', 4, 70, 84),
           ('33333333-3333-3333-3333-000000000004', '22222222-2222-2222-2222-000000000003', 5, 85, 100),
           ('33333333-3333-3333-3333-000000000005', '22222222-2222-2222-2222-000000000004', 2, 0, 39),
           ('33333333-3333-3333-3333-000000000006', '22222222-2222-2222-2222-000000000004', 3, 40, 59),
           ('33333333-3333-3333-3333-000000000007', '22222222-2222-2222-2222-000000000004', 4, 60, 79),
           ('33333333-3333-3333-3333-000000000008', '22222222-2222-2222-2222-000000000004', 5, 80, 100) AS new
ON DUPLICATE KEY UPDATE quiz_id   = new.quiz_id,
                        mark      = new.mark,
                        min_score = new.min_score,
                        max_score = new.max_score;

-- Вопросы SQL-квиза
INSERT INTO quiz_question (id, quiz_id, text, type, position)
    VALUES ('44444444-4444-4444-4444-000000000001', '22222222-2222-2222-2222-000000000003',
            'Какие из команд относятся к DML?', 'multiple_choice', 1),
           ('44444444-4444-4444-4444-000000000002', '22222222-2222-2222-2222-000000000003',
            'Расположите этапы выполнения SQL-запроса в правильном порядке', 'sequence', 2),
           ('44444444-4444-4444-4444-000000000003', '22222222-2222-2222-2222-000000000003',
            'Какой оператор используется для объединения таблиц?', 'multiple_choice', 3) AS new
ON DUPLICATE KEY UPDATE quiz_id  = new.quiz_id,
                        text     = new.text,
                        type     = new.type,
                        position = new.position;

-- Варианты: множественный выбор для SQL-квиза
INSERT INTO multiple_choice_question_available_values (id, question_id, value, is_correct)
    VALUES ('55555555-5555-5555-5555-000000000001', '44444444-4444-4444-4444-000000000001', 'SELECT', 1),
           ('55555555-5555-5555-5555-000000000002', '44444444-4444-4444-4444-000000000001', 'INSERT', 1),
           ('55555555-5555-5555-5555-000000000003', '44444444-4444-4444-4444-000000000001', 'CREATE', 0),
           ('55555555-5555-5555-5555-000000000004', '44444444-4444-4444-4444-000000000001', 'UPDATE', 1),
           ('55555555-5555-5555-5555-000000000005', '44444444-4444-4444-4444-000000000001', 'DROP', 0),
           ('55555555-5555-5555-5555-000000000006', '44444444-4444-4444-4444-000000000003', 'JOIN', 1),
           ('55555555-5555-5555-5555-000000000007', '44444444-4444-4444-4444-000000000003', 'MERGE', 0),
           ('55555555-5555-5555-5555-000000000008', '44444444-4444-4444-4444-000000000003', 'COMBINE', 0),
           ('55555555-5555-5555-5555-000000000009', '44444444-4444-4444-4444-000000000003', 'CONCATENATE', 0) AS new
ON DUPLICATE KEY UPDATE question_id = new.question_id,
                        value       = new.value,
                        is_correct  = new.is_correct;

-- Варианты: последовательность для SQL-квиза
-- Порядок: FROM -> WHERE -> GROUP BY -> SELECT -> ORDER BY
INSERT INTO sequence_question_available_values (id, question_id, value, next_value_id)
    VALUES ('66666666-6666-6666-6666-000000000001', '44444444-4444-4444-4444-000000000002', 'FROM', NULL),
           ('66666666-6666-6666-6666-000000000002', '44444444-4444-4444-4444-000000000002', 'WHERE', NULL),
           ('66666666-6666-6666-6666-000000000003', '44444444-4444-4444-4444-000000000002', 'GROUP BY', NULL),
           ('66666666-6666-6666-6666-000000000004', '44444444-4444-4444-4444-000000000002', 'SELECT', NULL),
           ('66666666-6666-6666-6666-000000000005', '44444444-4444-4444-4444-000000000002', 'ORDER BY', NULL) AS new
ON DUPLICATE KEY UPDATE question_id   = new.question_id,
                        value         = new.value,
                        next_value_id = new.next_value_id;
-- обновляем в связный свисок
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000002'
WHERE id = '66666666-6666-6666-6666-000000000001';
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000003'
WHERE id = '66666666-6666-6666-6666-000000000002';
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000004'
WHERE id = '66666666-6666-6666-6666-000000000003';
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000005'
WHERE id = '66666666-6666-6666-6666-000000000004';

-- Вопросы сетевого квиза
INSERT INTO quiz_question (id, quiz_id, text, type, position)
    VALUES ('44444444-4444-4444-4444-000000000004', '22222222-2222-2222-2222-000000000004',
            'Какие протоколы работают на транспортном уровне OSI?', 'multiple_choice', 1),
           ('44444444-4444-4444-4444-000000000005', '22222222-2222-2222-2222-000000000004',
            'Расположите уровни модели OSI снизу вверх', 'sequence', 2) AS new
ON DUPLICATE KEY UPDATE quiz_id  = new.quiz_id,
                        text     = new.text,
                        type     = new.type,
                        position = new.position;
INSERT INTO multiple_choice_question_available_values (id, question_id, value, is_correct)
    VALUES ('55555555-5555-5555-5555-000000000010', '44444444-4444-4444-4444-000000000004', 'TCP', 1),
           ('55555555-5555-5555-5555-000000000011', '44444444-4444-4444-4444-000000000004', 'UDP', 1),
           ('55555555-5555-5555-5555-000000000012', '44444444-4444-4444-4444-000000000004', 'HTTP', 0),
           ('55555555-5555-5555-5555-000000000013', '44444444-4444-4444-4444-000000000004', 'IP', 0) AS new
ON DUPLICATE KEY UPDATE question_id = new.question_id,
                        value       = new.value,
                        is_correct  = new.is_correct;
INSERT INTO sequence_question_available_values (id, question_id, value, next_value_id)
    VALUES ('66666666-6666-6666-6666-000000000006', '44444444-4444-4444-4444-000000000005', 'Физический', NULL),
           ('66666666-6666-6666-6666-000000000007', '44444444-4444-4444-4444-000000000005', 'Канальный', NULL),
           ('66666666-6666-6666-6666-000000000008', '44444444-4444-4444-4444-000000000005', 'Сетевой', NULL),
           ('66666666-6666-6666-6666-000000000009', '44444444-4444-4444-4444-000000000005', 'Транспортный', NULL),
           ('66666666-6666-6666-6666-000000000010', '44444444-4444-4444-4444-000000000005', 'Прикладной', NULL) AS new
ON DUPLICATE KEY UPDATE question_id   = new.question_id,
                        value         = new.value,
                        next_value_id = new.next_value_id;
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000007'
WHERE id = '66666666-6666-6666-6666-000000000006';
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000008'
WHERE id = '66666666-6666-6666-6666-000000000007';
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000009'
WHERE id = '66666666-6666-6666-6666-000000000008';
UPDATE sequence_question_available_values
SET next_value_id = '66666666-6666-6666-6666-000000000010'
WHERE id = '66666666-6666-6666-6666-000000000009';

-- Назначения на крус
INSERT INTO enrollment (id, user_id, course_id, start_date, end_date)
    VALUES ('77777777-7777-7777-7777-000000000001', '11111111-1111-1111-1111-000000000001',
            '22222222-2222-2222-2222-000000000001', '2026-03-01 10:00:00', '2026-04-01 10:00:00'),
           ('77777777-7777-7777-7777-000000000002', '11111111-1111-1111-1111-000000000001',
            '22222222-2222-2222-2222-000000000003', '2026-03-05 10:00:00', '2026-04-05 10:00:00'),
           ('77777777-7777-7777-7777-000000000003', '11111111-1111-1111-1111-000000000002',
            '22222222-2222-2222-2222-000000000003', '2026-03-10 09:00:00', '2026-04-10 09:00:00'),
           ('77777777-7777-7777-7777-000000000004', '11111111-1111-1111-1111-000000000002',
            '22222222-2222-2222-2222-000000000004', '2026-03-12 09:00:00', '2026-04-12 09:00:00'),
           ('77777777-7777-7777-7777-000000000005', '11111111-1111-1111-1111-000000000003',
            '22222222-2222-2222-2222-000000000003', '2026-03-15 14:00:00', NULL),
           ('77777777-7777-7777-7777-000000000006', '11111111-1111-1111-1111-000000000004',
            '22222222-2222-2222-2222-000000000002', '2026-02-20 08:00:00', '2026-03-20 08:00:00') AS new
ON DUPLICATE KEY UPDATE user_id    = new.user_id,
                        course_id  = new.course_id,
                        start_date = new.start_date,
                        end_date   = new.end_date;

-- Попытки
INSERT INTO attempt (id, enrollment_id, start_date, end_date, score, duration)
    VALUES ('88888888-8888-8888-8888-000000000001', '77777777-7777-7777-7777-000000000002', '2026-03-06 12:00:00',
            '2026-03-06 12:18:00', 55, 1080),
           ('88888888-8888-8888-8888-000000000002', '77777777-7777-7777-7777-000000000002', '2026-03-08 13:00:00',
            '2026-03-08 13:15:00', 88, 900),
           ('88888888-8888-8888-8888-000000000003', '77777777-7777-7777-7777-000000000003', '2026-03-11 10:00:00',
            '2026-03-11 10:25:00', 72, 1500),
           ('88888888-8888-8888-8888-000000000004', '77777777-7777-7777-7777-000000000004', '2026-03-13 11:00:00',
            '2026-03-13 11:20:00', 65, 1200),
           ('88888888-8888-8888-8888-000000000005', '77777777-7777-7777-7777-000000000001', '2026-03-02 09:00:00',
            '2026-03-02 10:05:00', 100, 3900),
           ('88888888-8888-8888-8888-000000000006', '77777777-7777-7777-7777-000000000005', '2026-03-16 15:00:00', NULL,
            NULL, NULL),
           ('88888888-8888-8888-8888-000000000007', '77777777-7777-7777-7777-000000000006', '2026-02-21 19:00:00',
            '2026-02-21 19:40:00', 90, 2400) AS new
ON DUPLICATE KEY UPDATE enrollment_id = new.enrollment_id,
                        start_date    = new.start_date,
                        end_date      = new.end_date,
                        score         = new.score,
                        duration      = new.duration;

-- Ответы на вопросы
-- Попытка 1 (Анна, SQL-квиз, 55 баллов): Q1 частично, Q2 с ошибкой, Q3 верно
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, mc_value_id, seq_value_id)
    VALUES ('99999999-9999-9999-9999-000000000001',
            '88888888-8888-8888-8888-000000000001',
            '44444444-4444-4444-4444-000000000001',
            JSON_ARRAY('55555555-5555-5555-5555-000000000001', '55555555-5555-5555-5555-000000000002'),
            '55555555-5555-5555-5555-000000000001',
            NULL),

           ('99999999-9999-9999-9999-000000000002',
            '88888888-8888-8888-8888-000000000001',
            '44444444-4444-4444-4444-000000000002',
            JSON_ARRAY(
                    '66666666-6666-6666-6666-000000000001',
                    '66666666-6666-6666-6666-000000000003',
                    '66666666-6666-6666-6666-000000000002',
                    '66666666-6666-6666-6666-000000000004',
                    '66666666-6666-6666-6666-000000000005'
            ),
            NULL,
            '66666666-6666-6666-6666-000000000001'),

           ('99999999-9999-9999-9999-000000000003',
            '88888888-8888-8888-8888-000000000001',
            '44444444-4444-4444-4444-000000000003',
            JSON_ARRAY('55555555-5555-5555-5555-000000000006'),
            '55555555-5555-5555-5555-000000000006',
            NULL) AS new
ON DUPLICATE KEY UPDATE attempt_id   = new.attempt_id,
                        question_id  = new.question_id,
                        value        = new.value,
                        mc_value_id  = new.mc_value_id,
                        seq_value_id = new.seq_value_id;
-- Попытка 2 (Анна, SQL-квиз, 88 баллов): всё верно
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, mc_value_id, seq_value_id)
    VALUES ('99999999-9999-9999-9999-000000000004',
            '88888888-8888-8888-8888-000000000002',
            '44444444-4444-4444-4444-000000000001',
            JSON_ARRAY(
                    '55555555-5555-5555-5555-000000000001',
                    '55555555-5555-5555-5555-000000000002',
                    '55555555-5555-5555-5555-000000000004'
            ),
            '55555555-5555-5555-5555-000000000001',
            NULL),

           ('99999999-9999-9999-9999-000000000005',
            '88888888-8888-8888-8888-000000000002',
            '44444444-4444-4444-4444-000000000002',
            JSON_ARRAY(
                    '66666666-6666-6666-6666-000000000001',
                    '66666666-6666-6666-6666-000000000002',
                    '66666666-6666-6666-6666-000000000003',
                    '66666666-6666-6666-6666-000000000004',
                    '66666666-6666-6666-6666-000000000005'
            ),
            NULL,
            '66666666-6666-6666-6666-000000000001'),

           ('99999999-9999-9999-9999-000000000006',
            '88888888-8888-8888-8888-000000000002',
            '44444444-4444-4444-4444-000000000003',
            JSON_ARRAY('55555555-5555-5555-5555-000000000006'),
            '55555555-5555-5555-5555-000000000006',
            NULL) AS new
ON DUPLICATE KEY UPDATE attempt_id   = new.attempt_id,
                        question_id  = new.question_id,
                        value        = new.value,
                        mc_value_id  = new.mc_value_id,
                        seq_value_id = new.seq_value_id;
-- Попытка 3 (Борис, SQL-квиз, 72 балла)
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, mc_value_id, seq_value_id)
    VALUES ('99999999-9999-9999-9999-000000000007',
            '88888888-8888-8888-8888-000000000003',
            '44444444-4444-4444-4444-000000000001',
            JSON_ARRAY('55555555-5555-5555-5555-000000000001', '55555555-5555-5555-5555-000000000002'),
            '55555555-5555-5555-5555-000000000001',
            NULL),

           ('99999999-9999-9999-9999-000000000008',
            '88888888-8888-8888-8888-000000000003',
            '44444444-4444-4444-4444-000000000002',
            JSON_ARRAY(
                    '66666666-6666-6666-6666-000000000001',
                    '66666666-6666-6666-6666-000000000002',
                    '66666666-6666-6666-6666-000000000003',
                    '66666666-6666-6666-6666-000000000004',
                    '66666666-6666-6666-6666-000000000005'
            ),
            NULL,
            '66666666-6666-6666-6666-000000000001'),

           ('99999999-9999-9999-9999-000000000009',
            '88888888-8888-8888-8888-000000000003',
            '44444444-4444-4444-4444-000000000003',
            JSON_ARRAY('55555555-5555-5555-5555-000000000006'),
            '55555555-5555-5555-5555-000000000006',
            NULL) AS new
ON DUPLICATE KEY UPDATE attempt_id   = new.attempt_id,
                        question_id  = new.question_id,
                        value        = new.value,
                        mc_value_id  = new.mc_value_id,
                        seq_value_id = new.seq_value_id;

-- Попытка 4 (Борис, квиз по сетям, 65 баллов)
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, mc_value_id, seq_value_id)
    VALUES ('99999999-9999-9999-9999-000000000010',
            '88888888-8888-8888-8888-000000000004',
            '44444444-4444-4444-4444-000000000004',
            JSON_ARRAY(
                    '55555555-5555-5555-5555-000000000010',
                    '55555555-5555-5555-5555-000000000011',
                    '55555555-5555-5555-5555-000000000013'
            ),
            '55555555-5555-5555-5555-000000000010',
            NULL),

           ('99999999-9999-9999-9999-000000000011',
            '88888888-8888-8888-8888-000000000004',
            '44444444-4444-4444-4444-000000000005',
            JSON_ARRAY(
                    '66666666-6666-6666-6666-000000000006',
                    '66666666-6666-6666-6666-000000000007',
                    '66666666-6666-6666-6666-000000000008',
                    '66666666-6666-6666-6666-000000000009',
                    '66666666-6666-6666-6666-000000000010'
            ),
            NULL,
            '66666666-6666-6666-6666-000000000006') AS new
ON DUPLICATE KEY UPDATE attempt_id   = new.attempt_id,
                        question_id  = new.question_id,
                        value        = new.value,
                        mc_value_id  = new.mc_value_id,
                        seq_value_id = new.seq_value_id;