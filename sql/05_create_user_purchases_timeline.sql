/* ============================================================================
   ОПИСАНИЕ: Создание материализованной таблицы с хронологией покупок пользователей.
   Отсекает дублирующие события чека (diff_minutes = 0) и материализует индексы.
   ============================================================================ */

-- 1. Удаляем таблицу, если она уже существовала
DROP TABLE IF EXISTS user_purchases_timeline;

-- 2. Создаем и наполняем физическую таблицу
CREATE TABLE user_purchases_timeline AS
WITH first_view AS (
    SELECT 
        user_id,
        event_type,
        DATETIME(REPLACE(event_time, ' UTC', '')) AS now_time,
        MIN(DATETIME(REPLACE(event_time, ' UTC', ''))) OVER (PARTITION BY user_id) AS first_view
    FROM events
),
raw_timeline AS (
    SELECT
        user_id,
        now_time,
        LAG(now_time, 1, first_view) OVER (PARTITION BY user_id ORDER BY now_time) AS prev_purchase,
        ROUND(
            (JULIANDAY(now_time) - JULIANDAY(LAG(now_time, 1, first_view) OVER (PARTITION BY user_id ORDER BY now_time))) * 1440, 
            2
        ) AS diff_minutes
    FROM first_view
    WHERE event_type = 'purchase'
)
SELECT 
    user_id,
    now_time,
    prev_purchase,
    diff_minutes,
    DENSE_RANK() OVER (PARTITION BY user_id ORDER BY now_time) AS purchase_order
FROM raw_timeline
WHERE diff_minutes > 0 OR now_time = prev_purchase;

-- 3. Создаем индексы для мгновенного выполнения последующих аналитических выборок
CREATE INDEX idx_timeline_user_id ON user_purchases_timeline(user_id);
CREATE INDEX idx_timeline_purchase_order ON user_purchases_timeline(purchase_order);
