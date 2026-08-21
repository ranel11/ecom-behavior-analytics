SELECT 
    CASE 
        WHEN total_sessions > 1 THEN '2. other_cust (>1 session)' 
        ELSE '1. new_cust (1 session)' 
    END AS group_cust,
    ROUND(COUNT(user_id) * 100.0 / (SELECT COUNT(*) FROM dim_users), 1) AS percent_cust,
    ROUND(SUM(CASE WHEN is_buyer = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(user_id), 1) AS percent_buy_cust,
    ROUND(SUM(CASE WHEN total_cart > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(user_id), 1) AS percent_cart_cust,
    ROUND(
        SUM(CASE WHEN is_buyer = 1 THEN 1 ELSE 0 END) * 100.0 
        / NULLIF(SUM(CASE WHEN total_cart > 0 THEN 1 ELSE 0 END), 0), 
        1
    ) AS percent_buy_after_cart_cust,
    ROUND(AVG(ltv_revenue)) AS avg_ltv_revenue,
    ROUND(AVG(total_views)) AS avg_views_count
FROM dim_users
GROUP BY 1
ORDER BY 1;
