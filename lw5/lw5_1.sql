CREATE DATABASE IF NOT EXISTS my_file_system;

use my_file_system;

CREATE TABLE IF NOT EXISTS directories
(
    id   INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS dir_tree
(
    ancestor   INT NOT NULL,
    descendant INT NOT NULL,
    depth      INT NOT NULL,
    PRIMARY KEY (ancestor, descendant), -- однозначно детерминируем элемент
    FOREIGN KEY (ancestor) REFERENCES directories (id) ON DELETE CASCADE,
    FOREIGN KEY (descendant) REFERENCES directories (id) ON DELETE CASCADE
);

-- заполнение
INSERT IGNORE INTO directories(id, name)
VALUES (1, 'root'),
       (2, 'home'),
       (3, 'user1'),
       (4, 'docs'),
       (5, 'photos'),
       (6, 'user2'),
       (7, 'music'),
       (8, 'etc'),
       (9, 'nginx'),
       (10, 'var'),
       (11, 'log');

INSERT IGNORE INTO dir_tree (ancestor, descendant, depth)
VALUES
    -- root
    (1, 1, 0),
    (1, 2, 1),
    (1, 3, 2),
    (1, 4, 3),
    (1, 5, 3),
    (1, 6, 2),
    (1, 7, 3),
    (1, 8, 1),
    (1, 9, 2),
    (1, 10, 1),
    (1, 11, 2),
-- home
    (2, 2, 0),
    (2, 3, 1),
    (2, 4, 2),
    (2, 5, 2),
    (2, 6, 1),
    (2, 7, 2),
-- user1
    (3, 3, 0),
    (3, 4, 1),
    (3, 5, 1),
-- docs
    (4, 4, 0),
-- photos
    (5, 5, 0),
-- user2
    (6, 6, 0),
    (6, 7, 1),
-- music
    (7, 7, 0),
-- etc
    (8, 8, 0),
    (8, 9, 1),
-- nginx
    (9, 9, 0),
-- var
    (10, 10, 0),
    (10, 11, 1),
-- log
    (11, 11, 0);

-- извлечение поддерева
SELECT d.*
FROM directories d
         JOIN dir_tree t ON d.id = t.descendant
WHERE t.ancestor = 2;

-- поиск конкретного листа
SELECT d.*
FROM directories d
         LEFT JOIN dir_tree t ON d.id = t.ancestor AND t.depth > 0 -- нужны узлы, у которых нет потомков
WHERE t.ancestor IS NULL
  AND d.name = 'music';

-- Вывод списка родителей
SELECT d.*, t.depth
FROM directories d
         JOIN dir_tree t ON d.id = t.ancestor
WHERE t.descendant = 4 -- docs
  AND t.depth > 0;

-- Вывода списка всех соседних директорий (у которых общий родитель)
-- user1
SELECT d.*
FROM directories d
         JOIN dir_tree t ON d.id = t.descendant AND t.depth = 1
WHERE t.ancestor = (SELECT ancestor
                    FROM dir_tree dt
                    WHERE dt.descendant = 3
                      AND dt.depth = 1)
  AND d.id = 3;

-- Удаление поддерева
DELETE IGNORE
FROM directories
WHERE id IN (SELECT descendant
             FROM dir_tree
             WHERE ancestor = 3);
-- связи удалятся сами (ON DELETE CASCADE)

-- Вставку 3 элементов в одного родителя
-- транзакцией?
INSERT IGNORE INTO directories (name)
VALUES ('apache'),
       ('ssh'),
       ('cron');
SET @a = LAST_INSERT_ID();
SET @b = @a + 1;
SET @c = @a + 2;
-- связь на себя
INSERT INTO dir_tree (ancestor, descendant, depth)
VALUES (@a, @a, 0),
       (@b, @b, 0),
       (@c, @c, 0);
-- на предков
INSERT IGNORE INTO dir_tree(ancestor, descendant, depth)
SELECT ancestor, @a, depth + 1
FROM dir_tree
WHERE descendant = 8;
INSERT IGNORE INTO dir_tree(ancestor, descendant, depth)
SELECT ancestor, @b, depth + 1
FROM dir_tree
WHERE descendant = 8;
INSERT IGNORE INTO dir_tree(ancestor, descendant, depth)
SELECT ancestor, @c, depth + 1
FROM dir_tree
WHERE descendant = 8;

-- Удаление 2 элементов
DELETE IGNORE
FROM directories
WHERE id IN (5, 7);
-- todo: останутся потомки в directories
-- изменение:
DELETE
FROM directories
WHERE id IN (SELECT descendant
             FROM dir_tree
             WHERE ancestor IN (5, 7));

-- Перемещение элемента в другое поддерево
-- user1 от home к var
-- транзакцией?
WITH subtree AS (SELECT descendant
                 FROM dir_tree
                 WHERE ancestor = 3)
DELETE
FROM dir_tree
WHERE descendant IN (SELECT descendant
                     FROM subtree)
  AND ancestor NOT IN (SELECT descendant
                       FROM subtree);
INSERT INTO dir_tree (ancestor, descendant, depth)
SELECT super.ancestor, sub.descendant, super.depth + sub.depth + 1
FROM dir_tree super -- предки нового родителя
         JOIN dir_tree sub -- потомки корня перемещаемого поддерева(user1 включительно)
WHERE super.descendant = 10
  AND sub.ancestor = 3;