-- 5_2
-- view - дерево с полными путями и глубиной
CREATE
OR REPLACE VIEW view_tree AS
SELECT d.id,
       d.name,
       parent.id                                                 AS parent_id,
       parent.name                                               AS parent_name,
       (SELECT MAX(depth) FROM dir_tree WHERE descendant = d.id) AS level
FROM directories d
         LEFT JOIN dir_tree t ON t.descendant = d.id AND t.depth = 1
         LEFT JOIN directories parent ON parent.id = t.ancestor;

SELECT *
FROM view_tree;