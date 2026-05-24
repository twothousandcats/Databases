CREATE TABLE tree
(
    id        INT PRIMARY KEY,
    parent_id INT,
    name      VARCHAR(50)
);

INSERT INTO tree
VALUES (1, NULL, 'root'),
       (2, 1, 'A'),
       (3, 1, 'B'),
       (4, 2, 'A1'),
       (5, 3, 'B1');

-- сессия А
BEGIN;

-- блокируем строку id=2
UPDATE tree
SET name = 'A_modified'
WHERE id = 2;

-- переключение

UPDATE tree
SET name = 'B_modified'
WHERE id = 3;

COMMIT;

-- сессия B
BEGIN;

-- блокируем строку id=3
UPDATE tree SET name = 'B_other' WHERE id = 3;

-- deadlock
UPDATE tree SET name = 'A_other' WHERE id = 2;

COMMIT;