CREATE
DATABASE IF NOT EXISTS courses_db;

USE
courses_db;

-- Пользователи
CREATE TABLE IF NOT EXISTS user
(
    id
    BINARY(16)   NOT NULL,
    name       VARCHAR(255) NULL,
    email      VARCHAR(255) NOT NULL,
    state      ENUM
(
    'active',
    'inactive',
    'fired'
)    NOT NULL DEFAULT 'active',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME     NULL,
    PRIMARY KEY
(
    id
),
    UNIQUE INDEX uq_user_email
(
    email
    ASC
)
    ) ENGINE = InnoDB;

-- Курс
-- course_type — связь, с сущностями video / audio / quiz
CREATE TABLE IF NOT EXISTS course
(
    id
    BINARY(16)   NOT NULL,
    name        VARCHAR(255) NOT NULL,
    description TEXT         NULL,
    course_type ENUM
(
    'video',
    'audio',
    'quiz'
)    NOT NULL,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at  DATETIME     NULL,
    PRIMARY KEY
(
    id
),
    INDEX idx_course_type
(
    course_type
    ASC
)
    ) ENGINE = InnoDB;

-- Видео-курс
CREATE TABLE IF NOT EXISTS video
(
    course_id
    BINARY(16)      NOT NULL,
    source_url VARCHAR(500)    NOT NULL,
    duration   INT UNSIGNED    NOT NULL, -- сек
    format     ENUM
(
    'mp4',
    'webm',
    'mov',
    'avi',
    'mkv'
)       NOT NULL,
    size       BIGINT UNSIGNED NOT NULL, -- байт
    created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    course_id
),
    CONSTRAINT fk_video_course
    FOREIGN KEY
(
    course_id
)
    REFERENCES course
(
    id
)
                                                                  ON DELETE CASCADE
                                                                  ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Аудио-курс
CREATE TABLE IF NOT EXISTS audio
(
    course_id
    BINARY(16)   NOT NULL,
    source_url VARCHAR(500) NOT NULL,
    duration   INT UNSIGNED NOT NULL COMMENT 'в секундах',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    course_id
),
    CONSTRAINT fk_audio_course
    FOREIGN KEY
(
    course_id
)
    REFERENCES course
(
    id
)
                                                               ON DELETE CASCADE
                                                               ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Квиз
-- available_duration - время на прохождение
-- weight - цена за прохождение
CREATE TABLE IF NOT EXISTS quiz
(
    course_id
    BINARY(16)   NOT NULL,
    source_url         VARCHAR(500) NULL,
    weight             DECIMAL(5,
                               2)       NULL,
    available_duration INT UNSIGNED NULL, -- сек
    state              ENUM
(
    'uploaded',
    'processed',
    'ready'
)    NOT NULL DEFAULT 'uploaded',
    created_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    course_id
),
    CONSTRAINT fk_quiz_course
    FOREIGN KEY
(
    course_id
)
    REFERENCES course
(
    id
)
                                                                       ON DELETE CASCADE
                                                                       ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Шкала оценок конкретного квиза
-- для quiz X оценка 5 ставится за 85-100 баллов
-- Пересечение диапазонов проверяется на уровне приложения
CREATE TABLE IF NOT EXISTS quiz_mark
(
    id
    BINARY(16)       NOT NULL,
    quiz_id    BINARY(16)       NOT NULL,
    mark       TINYINT UNSIGNED NOT NULL,
    min_score  TINYINT UNSIGNED NOT NULL,
    max_score  TINYINT UNSIGNED NOT NULL,
    created_at DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    id
),
    UNIQUE INDEX uq_quiz_mark
(
    quiz_id
    ASC,
    mark
    ASC
),
    INDEX idx_quiz_mark_range
(
    quiz_id
    ASC,
    min_score
    ASC,
    max_score
    ASC
),
    CONSTRAINT fk_quiz_mark_quiz
    FOREIGN KEY
(
    quiz_id
)
    REFERENCES quiz
(
    course_id
)
                                                                   ON DELETE CASCADE
                                                                   ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Вопросы квиза
CREATE TABLE IF NOT EXISTS quiz_question
(
    id
    BINARY(16)   NOT NULL,
    quiz_id     BINARY(16)   NOT NULL,
    text        TEXT         NOT NULL,
    type        ENUM
(
    'multiple_choice',
    'sequence'
)    NOT NULL,
    picture_url VARCHAR(500) NULL,
    position    INT UNSIGNED NOT NULL DEFAULT 0,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    id
),
    UNIQUE INDEX uq_quiz_question_position
(
    quiz_id
    ASC,
    position
    ASC
),
    CONSTRAINT fk_quiz_question_quiz
    FOREIGN KEY
(
    quiz_id
)
    REFERENCES quiz
(
    course_id
)
                                                                ON DELETE CASCADE
                                                                ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Варианты ответа: множественный выбор
CREATE TABLE IF NOT EXISTS multiple_choice_question_available_values
(
    id
    BINARY(16)   NOT NULL,
    question_id BINARY(16)   NOT NULL,
    value       VARCHAR(500) NOT NULL,
    is_correct  TINYINT(1)   NOT NULL DEFAULT 0,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    id
),
    CONSTRAINT fk_mc_values_question
    FOREIGN KEY
(
    question_id
)
    REFERENCES quiz_question
(
    id
)
                                                                ON DELETE CASCADE
                                                                ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Варианты ответа: последовательность
-- порядок — связный список через next_value_id
-- последний next_value_id: NULL
CREATE TABLE IF NOT EXISTS sequence_question_available_values
(
    id
    BINARY(16)   NOT NULL,
    question_id   BINARY(16)   NOT NULL,
    value         VARCHAR(500) NOT NULL,
    next_value_id BINARY(16)   NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    id
),
    CONSTRAINT fk_seq_values_question
    FOREIGN KEY
(
    question_id
)
    REFERENCES quiz_question
(
    id
)
                                                                  ON DELETE CASCADE
                                                                  ON UPDATE NO ACTION,
    CONSTRAINT fk_seq_values_next
    FOREIGN KEY
(
    next_value_id
)
    REFERENCES sequence_question_available_values
(
    id
)
                                                                  ON DELETE SET NULL
                                                                  ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Назначение пользователя на курс
CREATE TABLE IF NOT EXISTS enrollment
(
    id
    BINARY(16) NOT NULL,
    user_id    BINARY(16) NOT NULL,
    course_id  BINARY(16) NOT NULL,
    start_date DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_date   DATETIME   NULL,
    created_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    id
),
    UNIQUE INDEX uq_enrollment_user_course
(
    user_id
    ASC,
    course_id
    ASC
),
    CONSTRAINT fk_enrollment_user
    FOREIGN KEY
(
    user_id
)
    REFERENCES user
(
    id
)
                                                             ON DELETE CASCADE
                                                             ON UPDATE NO ACTION,
    CONSTRAINT fk_enrollment_course
    FOREIGN KEY
(
    course_id
)
    REFERENCES course
(
    id
)
                                                             ON DELETE CASCADE
                                                             ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Попытка прохождения
-- score — итоговый балл
-- квиз - 0 .. 100
-- видео/аудио - % просмотра/прослушивания
-- duration — длительность попытки в секундах
CREATE TABLE IF NOT EXISTS attempt
(
    id
    BINARY(16)       NOT NULL,
    enrollment_id BINARY(16)       NOT NULL,
    start_date    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_date      DATETIME         NULL,
    score         TINYINT UNSIGNED NULL,
    duration      INT UNSIGNED     NULL,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    id
),
    CONSTRAINT fk_attempt_enrollment
    FOREIGN KEY
(
    enrollment_id
)
    REFERENCES enrollment
(
    id
)
                                                                      ON DELETE CASCADE
                                                                      ON UPDATE NO ACTION
    ) ENGINE = InnoDB;


-- Ответ на вопрос в рамках попытки
-- value — JSON-массив UUID выбранных вариантов:
--   1) multiple_choice — порядок неважен: [uuid1, uuid2]
--   2) sequence — порядок = ответ пользователя: [uuid3, uuid1, uuid2]
-- mc_value_id / seq_value_id — опциональная ссылка на первый выбранный вариант для ссылочной целостности
-- Из двух полей заполнено ровно одно (в зависимости от типа вопроса)
-- уникальность будет обеспечиваться на уровне исполнения приложения
-- todo: mc_value_id, seq_value_id - отказаться
-- отказался от mc_value_id, seq_value_id, теперь данные берем из value и смотрим в question_id
-- left join
CREATE TABLE IF NOT EXISTS quiz_attempt_answer
(
    id          BINARY(16) NOT NULL,
    attempt_id  BINARY(16) NOT NULL,
    question_id BINARY(16) NOT NULL,
    value       JSON       NOT NULL,
    is_correct  TINYINT(1) NOT NULL DEFAULT 0,
    created_at  DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY
(
    id
),
    UNIQUE INDEX uq_answer_attempt_question
(
    attempt_id
    ASC,
    question_id
    ASC
),
    CONSTRAINT fk_answer_attempt
    FOREIGN KEY
(
    attempt_id
)
    REFERENCES attempt
(
    id
)
                                                              ON DELETE CASCADE
                                                              ON UPDATE NO ACTION,
    CONSTRAINT fk_answer_question
    FOREIGN KEY
(
    question_id
)
    REFERENCES quiz_question
(
    id
)
                                                              ON DELETE CASCADE
                                                              ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- ============================================
-- Пользователи
-- ============================================
INSERT INTO user (id, name, email, state)
VALUES (UUID_TO_BIN('11111111-1111-1111-1111-000000000001'), 'Анна Иванова', 'anna@example.com', 'active'),
       (UUID_TO_BIN('11111111-1111-1111-1111-000000000002'), 'Борис Петров', 'boris@example.com', 'active'),
       (UUID_TO_BIN('11111111-1111-1111-1111-000000000003'), NULL, 'guest@example.com', 'active'),
       (UUID_TO_BIN('11111111-1111-1111-1111-000000000004'), 'Дмитрий Сидоров', 'dmitry@example.com', 'inactive'),
       (UUID_TO_BIN('11111111-1111-1111-1111-000000000005'), 'Елена Козлова', 'elena@example.com', 'fired'),
       (UUID_TO_BIN('11111111-1111-1111-1111-000000000006'), 'Фёдор Волков', 'fedor@example.com', 'fired');

UPDATE user
SET deleted_at = '2024-12-01 00:00:00'
WHERE id IN (UUID_TO_BIN('11111111-1111-1111-1111-000000000005'),
             UUID_TO_BIN('11111111-1111-1111-1111-000000000006'));

-- ============================================
-- Курсы
-- ============================================
INSERT INTO course (id, name, description, course_type)
VALUES (UUID_TO_BIN('22222222-2222-2222-2222-000000000001'), 'Введение в Python', 'Видеокурс по Python', 'video'),
       (UUID_TO_BIN('22222222-2222-2222-2222-000000000002'), 'Подкаст: история алгоритмов', 'Аудиокурс', 'audio'),
       (UUID_TO_BIN('22222222-2222-2222-2222-000000000003'), 'Проверка знаний: SQL', 'Квиз по SQL', 'quiz'),
       (UUID_TO_BIN('22222222-2222-2222-2222-000000000004'), 'Проверка знаний: сети', 'Квиз по сетям', 'quiz');

INSERT INTO video (course_id, source_url, duration, format, size)
VALUES (UUID_TO_BIN('22222222-2222-2222-2222-000000000001'),
        'https://cdn.example.com/python.mp4', 3600, 'mp4', 524288000);

INSERT INTO audio (course_id, source_url, duration)
VALUES (UUID_TO_BIN('22222222-2222-2222-2222-000000000002'),
        'https://cdn.example.com/algo.mp3', 2700);

INSERT INTO quiz (course_id, source_url, weight, available_duration, state)
VALUES (UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
        'https://cdn.example.com/sql.json', 1.00, 1800, 'ready'),
       (UUID_TO_BIN('22222222-2222-2222-2222-000000000004'),
        'https://cdn.example.com/net.json', 0.50, 1200, 'processed');

-- ============================================
-- Шкала оценок
-- ============================================
INSERT INTO quiz_mark (id, quiz_id, mark, min_score, max_score)
VALUES (UUID_TO_BIN('33333333-3333-3333-3333-000000000001'), UUID_TO_BIN('22222222-2222-2222-2222-000000000003'), 2, 0,
        49),
       (UUID_TO_BIN('33333333-3333-3333-3333-000000000002'), UUID_TO_BIN('22222222-2222-2222-2222-000000000003'), 3, 50,
        69),
       (UUID_TO_BIN('33333333-3333-3333-3333-000000000003'), UUID_TO_BIN('22222222-2222-2222-2222-000000000003'), 4, 70,
        84),
       (UUID_TO_BIN('33333333-3333-3333-3333-000000000004'), UUID_TO_BIN('22222222-2222-2222-2222-000000000003'), 5, 85,
        100),
       (UUID_TO_BIN('33333333-3333-3333-3333-000000000005'), UUID_TO_BIN('22222222-2222-2222-2222-000000000004'), 2, 0,
        39),
       (UUID_TO_BIN('33333333-3333-3333-3333-000000000006'), UUID_TO_BIN('22222222-2222-2222-2222-000000000004'), 3, 40,
        59),
       (UUID_TO_BIN('33333333-3333-3333-3333-000000000007'), UUID_TO_BIN('22222222-2222-2222-2222-000000000004'), 4, 60,
        79),
       (UUID_TO_BIN('33333333-3333-3333-3333-000000000008'), UUID_TO_BIN('22222222-2222-2222-2222-000000000004'), 5, 80,
        100);

-- ============================================
-- Вопросы SQL-квиза
-- ============================================
INSERT INTO quiz_question (id, quiz_id, text, type, position)
VALUES (UUID_TO_BIN('44444444-4444-4444-4444-000000000001'), UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
        'Какие из команд относятся к DML?', 'multiple_choice', 1),
       (UUID_TO_BIN('44444444-4444-4444-4444-000000000002'), UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
        'Расположите этапы выполнения SQL-запроса', 'sequence', 2),
       (UUID_TO_BIN('44444444-4444-4444-4444-000000000003'), UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
        'Какой оператор используется для объединения таблиц?', 'multiple_choice', 3);

INSERT INTO multiple_choice_question_available_values (id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('55555555-5555-5555-5555-000000000001'), UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        'SELECT', 1),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000002'), UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        'INSERT', 1),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000003'), UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        'CREATE', 0),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000004'), UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        'UPDATE', 1),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000005'), UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        'DROP', 0),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000006'), UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        'JOIN', 1),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000007'), UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        'MERGE', 0),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000008'), UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        'COMBINE', 0),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000009'), UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        'CONCATENATE', 0);

-- Sequence: FROM -> WHERE -> GROUP BY -> SELECT -> ORDER BY
INSERT INTO sequence_question_available_values (id, question_id, value, next_value_id)
VALUES (UUID_TO_BIN('66666666-6666-6666-6666-000000000001'), UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        'FROM', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000002'), UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        'WHERE', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000003'), UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        'GROUP BY', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000004'), UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        'SELECT', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000005'), UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        'ORDER BY', NULL);

UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000002')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000001');
UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000003')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000002');
UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000004')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000003');
UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000005')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000004');

-- ============================================
-- Вопросы сетевого квиза
-- ============================================
INSERT INTO quiz_question (id, quiz_id, text, type, position)
VALUES (UUID_TO_BIN('44444444-4444-4444-4444-000000000004'), UUID_TO_BIN('22222222-2222-2222-2222-000000000004'),
        'Какие протоколы работают на транспортном уровне OSI?', 'multiple_choice', 1),
       (UUID_TO_BIN('44444444-4444-4444-4444-000000000005'), UUID_TO_BIN('22222222-2222-2222-2222-000000000004'),
        'Расположите уровни модели OSI снизу вверх', 'sequence', 2);

INSERT INTO multiple_choice_question_available_values (id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('55555555-5555-5555-5555-000000000010'), UUID_TO_BIN('44444444-4444-4444-4444-000000000004'), 'TCP',
        1),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000011'), UUID_TO_BIN('44444444-4444-4444-4444-000000000004'), 'UDP',
        1),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000012'), UUID_TO_BIN('44444444-4444-4444-4444-000000000004'),
        'HTTP', 0),
       (UUID_TO_BIN('55555555-5555-5555-5555-000000000013'), UUID_TO_BIN('44444444-4444-4444-4444-000000000004'), 'IP',
        0);

INSERT INTO sequence_question_available_values (id, question_id, value, next_value_id)
VALUES (UUID_TO_BIN('66666666-6666-6666-6666-000000000006'), UUID_TO_BIN('44444444-4444-4444-4444-000000000005'),
        'Физический', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000007'), UUID_TO_BIN('44444444-4444-4444-4444-000000000005'),
        'Канальный', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000008'), UUID_TO_BIN('44444444-4444-4444-4444-000000000005'),
        'Сетевой', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000009'), UUID_TO_BIN('44444444-4444-4444-4444-000000000005'),
        'Транспортный', NULL),
       (UUID_TO_BIN('66666666-6666-6666-6666-000000000010'), UUID_TO_BIN('44444444-4444-4444-4444-000000000005'),
        'Прикладной', NULL);

UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000007')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000006');
UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000008')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000007');
UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000009')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000008');
UPDATE sequence_question_available_values
SET next_value_id = UUID_TO_BIN('66666666-6666-6666-6666-000000000010')
WHERE id = UUID_TO_BIN('66666666-6666-6666-6666-000000000009');

-- ============================================
-- Назначения
-- ============================================
INSERT INTO enrollment (id, user_id, course_id, start_date, end_date)
VALUES
    -- Анна (active) на SQL-квиз
    (UUID_TO_BIN('77777777-7777-7777-7777-000000000001'),
     UUID_TO_BIN('11111111-1111-1111-1111-000000000001'),
     UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
     '2024-12-01 10:00:00', NULL),
    -- Борис (active) на SQL-квиз
    (UUID_TO_BIN('77777777-7777-7777-7777-000000000002'),
     UUID_TO_BIN('11111111-1111-1111-1111-000000000002'),
     UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
     '2025-01-15 10:00:00', NULL),
    -- Гость (active) на SQL-квиз
    (UUID_TO_BIN('77777777-7777-7777-7777-000000000003'),
     UUID_TO_BIN('11111111-1111-1111-1111-000000000003'),
     UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
     '2025-02-10 10:00:00', NULL),
    -- Борис (active) на сетевой квиз
    (UUID_TO_BIN('77777777-7777-7777-7777-000000000004'),
     UUID_TO_BIN('11111111-1111-1111-1111-000000000002'),
     UUID_TO_BIN('22222222-2222-2222-2222-000000000004'),
     '2025-03-12 09:00:00', NULL),
    -- Дмитрий (inactive) на видео
    (UUID_TO_BIN('77777777-7777-7777-7777-000000000005'),
     UUID_TO_BIN('11111111-1111-1111-1111-000000000004'),
     UUID_TO_BIN('22222222-2222-2222-2222-000000000001'),
     '2025-02-20 08:00:00', NULL),
    -- Елена (fired) на SQL-квиз
    (UUID_TO_BIN('77777777-7777-7777-7777-000000000006'),
     UUID_TO_BIN('11111111-1111-1111-1111-000000000005'),
     UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
     '2024-05-10 10:00:00', '2024-06-10 10:00:00'),
    -- Фёдор (fired) на SQL-квиз
    (UUID_TO_BIN('77777777-7777-7777-7777-000000000007'),
     UUID_TO_BIN('11111111-1111-1111-1111-000000000006'),
     UUID_TO_BIN('22222222-2222-2222-2222-000000000003'),
     '2024-08-01 10:00:00', '2024-09-01 10:00:00');

-- ============================================
-- Попытки
-- ============================================
INSERT INTO attempt (id, enrollment_id, start_date, end_date, score, duration)
VALUES
    -- Анна, попытка 1: незавершённая (для запроса 2)
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000001'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000001'),
     '2025-03-06 12:00:00', NULL, NULL, NULL),
    -- Анна, попытка 2: идеально (для запроса 1 и 3)
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000002'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000001'),
     '2025-04-08 13:00:00', '2025-04-08 13:15:00', 100, 900),
    -- Борис, SQL: 2 из 3 (для запроса 3)
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000003'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000002'),
     '2025-05-11 10:00:00', '2025-05-11 10:25:00', 66, 1500),
    -- Гость, SQL: 2 из 3 ответов (для запроса 2)
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000004'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000003'),
     '2025-06-15 14:00:00', '2025-06-15 14:30:00', NULL, 1800),
    -- Борис, сети: незавершённая (для запроса 2)
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000005'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000004'),
     '2025-07-13 11:00:00', NULL, NULL, NULL),
    -- Елена (fired), попытка 1: 2 из 3 (для запроса 3)
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000006'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000006'),
     '2024-05-15 12:00:00', '2024-05-15 12:20:00', 66, 1200),
    -- Елена (fired), попытка 2: 1 из 3
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000007'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000006'),
     '2024-06-01 10:00:00', '2024-06-01 10:25:00', 33, 1500),
    -- Фёдор (fired): 3 из 3
    (UUID_TO_BIN('88888888-8888-8888-8888-000000000008'),
     UUID_TO_BIN('77777777-7777-7777-7777-000000000007'),
     '2024-08-10 09:00:00', '2024-08-10 09:18:00', 100, 1080);

-- ============================================
-- Ответы
-- ============================================

-- Анна, попытка 1: только Q1 (правильно), Q2 и Q3 не отвечены
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000001'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000001'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000001',
                   '55555555-5555-5555-5555-000000000002',
                   '55555555-5555-5555-5555-000000000004'), 1);

-- Анна, попытка 2: 3 из 3
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000002'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000002'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000001',
                   '55555555-5555-5555-5555-000000000002',
                   '55555555-5555-5555-5555-000000000004'), 1),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000003'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000002'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        JSON_ARRAY('66666666-6666-6666-6666-000000000001',
                   '66666666-6666-6666-6666-000000000002',
                   '66666666-6666-6666-6666-000000000003',
                   '66666666-6666-6666-6666-000000000004',
                   '66666666-6666-6666-6666-000000000005'), 1),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000004'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000002'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000006'), 1);

-- Борис, SQL: Q1 неверно (без UPDATE), Q2 верно, Q3 верно
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000005'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000003'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000001',
                   '55555555-5555-5555-5555-000000000002'), 0),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000006'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000003'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        JSON_ARRAY('66666666-6666-6666-6666-000000000001',
                   '66666666-6666-6666-6666-000000000002',
                   '66666666-6666-6666-6666-000000000003',
                   '66666666-6666-6666-6666-000000000004',
                   '66666666-6666-6666-6666-000000000005'), 1),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000007'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000003'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000006'), 1);

-- Гость, SQL: Q1 неверно (только SELECT), Q2 верно, Q3 не дан
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000008'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000004'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000001'), 0),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000009'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000004'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        JSON_ARRAY('66666666-6666-6666-6666-000000000001',
                   '66666666-6666-6666-6666-000000000002',
                   '66666666-6666-6666-6666-000000000003',
                   '66666666-6666-6666-6666-000000000004',
                   '66666666-6666-6666-6666-000000000005'), 1);

-- Борис, сети: только Q1 неполный (без UDP), Q2 не дан
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000010'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000005'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000004'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000010',
                   '55555555-5555-5555-5555-000000000011'), 1);
-- комментарий выше неточный: TCP+UDP — это и есть полный правильный набор, ставим 1

-- Елена, попытка 1: Q1 верно, Q2 верно, Q3 неверно (MERGE)
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000011'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000006'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000001',
                   '55555555-5555-5555-5555-000000000002',
                   '55555555-5555-5555-5555-000000000004'), 1),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000012'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000006'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        JSON_ARRAY('66666666-6666-6666-6666-000000000001',
                   '66666666-6666-6666-6666-000000000002',
                   '66666666-6666-6666-6666-000000000003',
                   '66666666-6666-6666-6666-000000000004',
                   '66666666-6666-6666-6666-000000000005'), 1),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000013'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000006'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000007'), 0);

-- Елена, попытка 2: Q1 неверно (CREATE), Q2 неверно (порядок), Q3 верно
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000014'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000007'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000003'), 0),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000015'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000007'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        JSON_ARRAY('66666666-6666-6666-6666-000000000004',
                   '66666666-6666-6666-6666-000000000001',
                   '66666666-6666-6666-6666-000000000002',
                   '66666666-6666-6666-6666-000000000003',
                   '66666666-6666-6666-6666-000000000005'), 0),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000016'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000007'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000006'), 1);

-- Фёдор: 3 из 3
INSERT INTO quiz_attempt_answer (id, attempt_id, question_id, value, is_correct)
VALUES (UUID_TO_BIN('99999999-9999-9999-9999-000000000017'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000008'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000001'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000001',
                   '55555555-5555-5555-5555-000000000002',
                   '55555555-5555-5555-5555-000000000004'), 1),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000018'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000008'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000002'),
        JSON_ARRAY('66666666-6666-6666-6666-000000000001',
                   '66666666-6666-6666-6666-000000000002',
                   '66666666-6666-6666-6666-000000000003',
                   '66666666-6666-6666-6666-000000000004',
                   '66666666-6666-6666-6666-000000000005'), 1),
       (UUID_TO_BIN('99999999-9999-9999-9999-000000000019'),
        UUID_TO_BIN('88888888-8888-8888-8888-000000000008'),
        UUID_TO_BIN('44444444-4444-4444-4444-000000000003'),
        JSON_ARRAY('55555555-5555-5555-5555-000000000006'), 1);


-- --------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------

-- когда важно имя
CREATE INDEX idx_course_name ON course (name);
-- когда важно учитывать активность пользователя
CREATE INDEX idx_user_state ON user (state);
-- когда важно учитывать состояние квиза
CREATE INDEX idx_quiz_state ON quiz (state);
--
CREATE INDEX idx_attempt_enrollment_score ON attempt (enrollment_id, score);
CREATE INDEX idx_attempt_enrollment_start ON attempt (enrollment_id, start_date);
CREATE INDEX idx_mc_question_correct ON multiple_choice_question_available_values (question_id, is_correct);

-- если добавляем is_correct quiz_attempt_answer
CREATE INDEX idx_qaa_attempt_correct ON quiz_attempt_answer (attempt_id, is_correct);

-- todo: 1
-- Извлечь имена всех активных пользователей,
-- которые правильно ответили на все вопросы готового к использованию квиза с названием <ваше название>.
-- Квиз должен быть не удалённым курсом.
-- Если у пользователя нет имени, отображать его email
SELECT DISTINCT COALESCE(NULLIF(u.name, ''), u.email) AS display_name
FROM user u
         JOIN enrollment e ON e.user_id = u.id
         JOIN course c ON c.id = e.course_id
         JOIN quiz q ON q.course_id = c.id
         JOIN attempt a ON a.enrollment_id = e.id
         JOIN quiz_question qq ON qq.quiz_id = c.id
         JOIN quiz_attempt_answer qa
              ON qa.attempt_id = a.id AND qa.question_id = qq.id
WHERE c.name = 'Проверка знаний: SQL'
  AND c.course_type = 'quiz'
  AND c.deleted_at IS NULL
  AND q.state = 'ready'
  AND u.state = 'active'
  AND u.deleted_at IS NULL
GROUP BY u.id, a.id
HAVING COUNT(qq.id) = SUM(qa.is_correct)
   AND COUNT(qq.id) = (SELECT COUNT(*) FROM quiz_question WHERE quiz_id = q.course_id);

-- todo: 2
-- Извлечь все прохождения, не пройденные до конца (когда один или несколько вопросов не пройдены).
-- Нужно извлечь имена пользователей и курсов, в которых есть такая ситуация.
-- Пара пользователь - курс не должна дублироваться
SELECT DISTINCT COALESCE(NULLIF(u.name, ''), u.email) AS user_display,
                c.name                                AS course_name
FROM attempt a
         JOIN enrollment e ON e.id = a.enrollment_id
         JOIN user u ON u.id = e.user_id
         JOIN course c ON c.id = e.course_id
         JOIN quiz_question qq ON qq.quiz_id = c.id
         LEFT JOIN quiz_attempt_answer qa
                   ON qa.attempt_id = a.id AND qa.question_id = qq.id
WHERE c.course_type = 'quiz'
  AND c.deleted_at IS NULL
  AND u.deleted_at IS NULL
  AND qa.id IS NULL;

-- todo 3
-- Подсчитать среднее количество вопросов в квизе,
-- на которые правильно ответили уволенные пользователи в период до 2025,
-- а также посчитать посчитать среднее количество вопросов в квизе,
-- на которые правильно ответили активные пользователи в период за 2025.
-- И сделать текстовый вывод, кто проходит квизы лучше.
-- Сделать в единый SQL запрос
WITH attempt_correct AS (SELECT a.id               AS attempt_id,
                                u.state,
                                a.start_date,
                                SUM(qa.is_correct) AS correct_count
                         FROM attempt a
                                  JOIN enrollment e ON e.id = a.enrollment_id
                                  JOIN user u ON u.id = e.user_id
                                  JOIN course c ON c.id = e.course_id AND c.course_type = 'quiz'
                                  JOIN quiz_attempt_answer qa ON qa.attempt_id = a.id
                         WHERE (u.state = 'fired' AND a.start_date < '2025-01-01')
                            OR (u.state = 'active' AND a.start_date >= '2025-01-01' AND a.start_date < '2026-01-01')
                         GROUP BY a.id, u.state, a.start_date)
SELECT ROUND(AVG(CASE WHEN state = 'fired' THEN correct_count END), 2)  AS avg_fired_before_2025,
       ROUND(AVG(CASE WHEN state = 'active' THEN correct_count END), 2) AS avg_active_2025,
       CASE
           WHEN AVG(CASE WHEN state = 'fired' THEN correct_count END)
               > AVG(CASE WHEN state = 'active' THEN correct_count END)
               THEN 'Уволенные (до 2025) лучше'
           WHEN AVG(CASE WHEN state = 'active' THEN correct_count END)
               > AVG(CASE WHEN state = 'fired' THEN correct_count END)
               THEN 'Активные (2025) лучше'
           ELSE 'Равны или нет данных'
           END                                                          AS verdict
FROM attempt_correct;