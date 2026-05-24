use
my_file_system;

-- полные пути всех директорий
DROP VIEW IF EXISTS v_dir_paths;
CREATE VIEW v_dir_paths AS
SELECT t.descendant                                             AS id,
       d.name                                                   AS name,
       GROUP_CONCAT(a.name ORDER BY t.depth DESC SEPARATOR '/') AS path
FROM dir_tree t
         JOIN directories d ON d.id = t.descendant
         JOIN directories a ON a.id = t.ancestor
GROUP BY t.descendant, d.name;

-- SELECT * FROM v_dir_paths WHERE name = 'nginx';


-- глубина директории от корня (root = 0)
DROP FUNCTION IF EXISTS fn_dir_depth;

CREATE FUNCTION fn_dir_depth(p_id INT)
    RETURNS INT
    DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE
v_depth INT;
SELECT depth
INTO v_depth
FROM dir_tree
WHERE ancestor = 1
  AND descendant = p_id;
RETURN v_depth;
END;
-- SELECT fn_dir_depth(4);  -- docs -> 3


-- перемещение поддерева в нового родителя
DROP PROCEDURE IF EXISTS sp_move_subtree;

CREATE PROCEDURE sp_move_subtree(IN p_node INT, IN p_new_parent INT)
BEGIN
    -- защита от перемещения внутрь собственного поддерева
    IF
EXISTS (SELECT 1
                FROM dir_tree
                WHERE ancestor = p_node
                  AND descendant = p_new_parent) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot move node into its own subtree';
END IF;

START TRANSACTION;

-- отрываем поддерево от старых предков
DELETE
FROM dir_tree
WHERE descendant IN (SELECT descendant
                     FROM (SELECT descendant
                           FROM dir_tree
                           WHERE ancestor = p_node) AS sub)
  AND ancestor NOT IN (SELECT descendant
                       FROM (SELECT descendant
                             FROM dir_tree
                             WHERE ancestor = p_node) AS sub2);

-- привязываем к новым предкам
INSERT INTO dir_tree (ancestor, descendant, depth)
SELECT super.ancestor, sub.descendant, super.depth + sub.depth + 1
FROM dir_tree super
         JOIN dir_tree sub
WHERE super.descendant = p_new_parent
  AND sub.ancestor = p_node;
COMMIT;
END;