-- ====================================================================
-- Analytical Queries for mart_06_purchase_paths_matrix
-- Purpose: Habit Loops, Aha-moment detection, and Churn Transition Analysis
-- ====================================================================

-- 1. Habit Loop Detection (Поиск устойчивых петель привычки 24h)
-- Выявляет удержание пользователей, зациклившихся в ритме "24h"
SELECT 
    purchase_order,
    time_int,
    prev_1, prev_2, prev_3, prev_4,
    current_count,
    parent_count,
    percent AS retention_pct
FROM purchase_paths_matrix
WHERE purchase_order >= 4
  AND time_int = '24h'
  AND prev_1 = '24h'
  AND prev_2 = '24h'
  AND prev_3 = '24h'
  AND parent_count >= 10
ORDER BY purchase_order ASC;

-- 2. Aha-Moment / Point of No Return (Поиск точки невозврата)
-- Оценка удержания в разрезе номера покупки и интервала
SELECT 
    purchase_order,
    time_int,
    SUM(current_count) AS users_in_loop,
    SUM(parent_count) AS total_eligible_users,
    ROUND(SUM(current_count) * 100.0 / NULLIF(SUM(parent_count), 0), 2) AS loop_retention_pct
FROM purchase_paths_matrix
WHERE time_int = prev_1 
  AND prev_1 = prev_2
  AND parent_count >= 10
GROUP BY purchase_order, time_int
ORDER BY time_int, purchase_order ASC;

-- 3. Transition Breakdown at Step 3 (Анализ сбива ритма со 2-й на 3-ю покупку)
-- Распределение следующих интервалов для пользователей из 24h
SELECT 
    time_int AS next_interval,
    current_count,
    parent_count,
    ROUND(current_count * 100.0 / NULLIF(parent_count, 0), 2) AS transition_pct
FROM purchase_paths_matrix
WHERE purchase_order = 3
  AND prev_1 = '24h'
ORDER BY current_count DESC;

-- 4. Churn / Pattern Breakdown at Step 4 (Срыв привычки на 4-й покупке)
-- Куда уходят пользователи после цепочки 24h -> 24h -> 24h
SELECT 
    time_int AS new_interval,
    current_count,
    parent_count,
    percent AS drop_pct
FROM purchase_paths_matrix
WHERE purchase_order = 4
  AND prev_1 = '24h' 
  AND prev_2 = '24h' 
  AND prev_3 = '24h'
ORDER BY current_count DESC;
