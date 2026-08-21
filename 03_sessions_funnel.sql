/* ============================================================================
   ОПИСАНИЕ: Расчет общей сессионной воронки (Просмотр -> Корзина -> Покупка),
   абсолютного количества сессий и итоговых конверсий (CR %).
   ============================================================================ */

SELECT 
    -- 1. Абсолютные показатели
    COUNT(user_session) AS total_sessions,
    SUM(has_view) AS sessions_with_views,
    SUM(has_cart) AS sessions_with_cart,
    SUM(has_purchase) AS sessions_with_purchase,
    
    -- 2. Конверсия из сессии с просмотром в корзину (%)
    ROUND(
        SUM(has_cart) * 100.0 / NULLIF(SUM(has_view), 0), 
        1
    ) AS CR_view_to_cart,
    
    -- 3. Конверсия из корзины в покупку / Чекаут (%)
    ROUND(
        SUM(has_purchase) * 100.0 / NULLIF(SUM(has_cart), 0), 
        1
    ) AS CR_cart_to_purchase,
    
    -- 4. Итоговая сквозная конверсия всей сессии в покупку (%)
    ROUND(
        SUM(has_purchase) * 100.0 / COUNT(user_session), 
        1
    ) AS total_session_CR

FROM dim_sessions;
