DROP TABLE IF EXISTS dim_sessions;

CREATE TABLE dim_sessions AS
SELECT 
    user_session, 
    user_id, 
    MIN(event_time) AS start_session, 
    MAX(event_time) AS end_session, 
    CAST(UNIXEPOCH(SUBSTR(MAX(event_time), 1, 19)) - UNIXEPOCH(SUBSTR(MIN(event_time), 1, 19)) AS INTEGER) AS session_duration_sec,
    SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS views_count,
    SUM(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS cart_count,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END), 2) AS total_revenue,
    MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
FROM events
WHERE user_session IS NOT NULL
GROUP BY user_session, user_id;