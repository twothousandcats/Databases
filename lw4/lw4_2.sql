USE courses_db;

-- --------------------------------------------------------------------------------
-- когда важно имя
CREATE INDEX idx_course_name ON course (name);
-- когда важно учитывать активность пользователя (насколько важно хранить уволенных/неактивных)
# CREATE INDEX idx_user_state ON user (state);
-- когда важно учитывать состояние квиза
-- зависит от кол-ва хранимых неактивных квизов, как будто бы почти 99% будет готовыми
# CREATE INDEX idx_quiz_state ON quiz (state);

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