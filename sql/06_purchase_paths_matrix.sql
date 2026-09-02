-- Удаляем таблицу, если она уже существовала
DROP TABLE IF EXISTS purchase_paths_matrix;

-- Создаем и наполняем материализованную таблицу
CREATE TABLE purchase_paths_matrix AS
WITH lagged_timeline AS (
    SELECT 
        user_id,
        purchase_order,
        diff_minutes,
        CASE
            WHEN diff_minutes <= 1440 THEN '24h'
            WHEN diff_minutes > 1440 AND diff_minutes <= 4320 THEN '1-3d'
            WHEN diff_minutes > 4320 AND diff_minutes <= 10080 THEN '4-7d'
            ELSE '8d'
        END AS time_int
    FROM user_purchases_timeline
),
prev_time_int AS (
    SELECT 
        user_id,
        time_int,
        purchase_order, 
        LAG(time_int, 1) OVER(PARTITION BY user_id ORDER BY purchase_order) AS prev_1,
        LAG(time_int, 2) OVER(PARTITION BY user_id ORDER BY purchase_order) AS prev_2,
        LAG(time_int, 3) OVER(PARTITION BY user_id ORDER BY purchase_order) AS prev_3,
        LAG(time_int, 4) OVER(PARTITION BY user_id ORDER BY purchase_order) AS prev_4,
        LAG(time_int, 5) OVER(PARTITION BY user_id ORDER BY purchase_order) AS prev_5
    FROM lagged_timeline
),
parent_counts AS (
    SELECT 
        purchase_order + 1 AS target_purchase_order,
        time_int AS parent_time_int,
        prev_1 AS parent_prev_1,
        prev_2 AS parent_prev_2,
        prev_3 AS parent_prev_3,
        prev_4 AS parent_prev_4,
        COUNT(DISTINCT user_id) AS parent_count
    FROM prev_time_int
    GROUP BY 1, 2, 3, 4, 5, 6
),
current_counts AS (
    SELECT 
        purchase_order,
        time_int,
        prev_1, prev_2, prev_3, prev_4, prev_5,
        COUNT(DISTINCT user_id) AS current_count
    FROM prev_time_int
    GROUP BY purchase_order, time_int, prev_1, prev_2, prev_3, prev_4, prev_5
)
SELECT 
    c.time_int,
    c.purchase_order, 
    c.prev_1, c.prev_2, c.prev_3, c.prev_4, c.prev_5,
    c.current_count,
    CASE 
        WHEN c.purchase_order = 1 THEN c.current_count 
        ELSE p.parent_count 
    END AS parent_count,
    CASE 
        WHEN c.purchase_order = 1 THEN 100.0
        ELSE ROUND(c.current_count * 100.0 / NULLIF(p.parent_count, 0), 2)
    END AS percent
FROM current_counts c
LEFT JOIN parent_counts p
       ON c.purchase_order > 1
      AND p.target_purchase_order = c.purchase_order
      AND p.parent_time_int = c.prev_1
      AND COALESCE(p.parent_prev_1, '') = COALESCE(c.prev_2, '')
      AND COALESCE(p.parent_prev_2, '') = COALESCE(c.prev_3, '')
      AND COALESCE(p.parent_prev_3, '') = COALESCE(c.prev_4, '')
      AND COALESCE(p.parent_prev_4, '') = COALESCE(c.prev_5, '');

-- Индексы для мгновенной фильтрации и анализа цепочек
CREATE INDEX idx_ppm_order ON purchase_paths_matrix(purchase_order);
CREATE INDEX idx_ppm_time_int ON purchase_paths_matrix(time_int);
