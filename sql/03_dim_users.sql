CREATE TABLE dim_users AS
SELECT 
    user_id,
    
    -- Lifetime (дней между первой и последней сессией)
    CAST(
        (UNIXEPOCH(SUBSTR(MAX(end_session), 1, 19)) - UNIXEPOCH(SUBSTR(MIN(start_session), 1, 19))) / 86400 
    AS INTEGER) AS lifetime_days,
    
    -- Recency (сколько дней прошло от даты последней сессии юзера до конца базы)
    -- Берем максимальную дату базы как точку отсчета:
    CAST(
        ((SELECT UNIXEPOCH(SUBSTR(MAX(end_session), 1, 19)) FROM dim_sessions) - UNIXEPOCH(SUBSTR(MAX(end_session), 1, 19))) / 86400 
    AS INTEGER) AS recency_days,

    COUNT(user_session) AS total_sessions,
    SUM(views_count) AS total_views,
    SUM(cart_count) AS total_cart,
    SUM(purchase_count) AS total_purchases,
    ROUND(SUM(total_revenue), 2) AS ltv_revenue,
    
    -- Флаг покупателя (1 если были покупки, иначе 0)
    MAX(has_purchase) AS is_buyer

FROM dim_sessions
GROUP BY user_id;
