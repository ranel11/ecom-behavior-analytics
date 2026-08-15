-- ============================================================
-- 01. DATA QUALITY CHECKS (Аудит качества данных)
-- ============================================================

-- 1. Проверка временных рамок (Time Range)
SELECT 
    MIN(event_time) AS min_event_time, 
    MAX(event_time) AS max_event_time
FROM events;

-- 2. Уникальные типы событий
SELECT DISTINCT event_type 
FROM events;

-- 3. Распределение видов событий (Воронка верхнего уровня)
SELECT 
    event_type, 
    COUNT(event_type) AS count
FROM events
GROUP BY event_type
ORDER BY count DESC;

-- 4. Общие метрики стоимости (Price Integrity)
SELECT 
    MIN(price) AS min_price, 
    MAX(price) AS max_price, 
    AVG(price) AS avg_price
FROM events;

-- 5. Проверка транзакций с нулевыми/аномальными ценами при покупке
SELECT 
    MIN(price) AS min_purchase_price, 
    MAX(price) AS max_purchase_price, 
    AVG(price) AS avg_purchase_price
FROM events
WHERE event_type = 'purchase';

-- 6. Проверка процента заполненности полей (Completeness / Null Checks)
SELECT 
    (SUM(CASE WHEN user_session IS NOT NULL THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS percent_user_session, 
    (SUM(CASE WHEN category_code IS NOT NULL THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS percent_category_code,
    (SUM(CASE WHEN brand IS NOT NULL THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS percent_brand
FROM events;
