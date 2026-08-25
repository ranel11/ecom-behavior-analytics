-- ==============================================================================
-- Script: time_to_purchase_matrix.sql
-- Description: Calculation of time-to-purchase intervals and repurchase cohort matrix
-- ==============================================================================

WITH lagged_timeline AS (
    SELECT 
        user_id,
        purchase_order,
        diff_minutes,
        CASE
            WHEN diff_minutes <= 1440 THEN '24h'
            WHEN diff_minutes > 1440 AND diff_minutes <= 4320 THEN '1-3d'
            WHEN diff_minutes > 4320 AND diff_minutes <= 10080 THEN '4-7d'
            WHEN diff_minutes > 10080 THEN '8d'
        END AS time_int,
        LEAD(diff_minutes) OVER (
            PARTITION BY user_id 
            ORDER BY purchase_order
        ) AS next_diff_minutes
    FROM user_purchases_timeline
),
first_second AS (
    SELECT 
        time_int, 
        diff_minutes, 
        next_diff_minutes, 
        COUNT(*) OVER () AS count_first_purchase
    FROM lagged_timeline
    WHERE purchase_order = 1
)
SELECT 
    time_int,
    COUNT(diff_minutes) * 100 / count_first_purchase AS first_purchase, 
    SUM(CASE WHEN next_diff_minutes IS NOT NULL AND next_diff_minutes <= 1440 THEN 1 ELSE 0 END) * 100 / COUNT(next_diff_minutes) AS second_24h,
    SUM(CASE WHEN next_diff_minutes IS NOT NULL AND next_diff_minutes > 1440 AND next_diff_minutes <= 4320 THEN 1 ELSE 0 END) * 100 / COUNT(next_diff_minutes) AS second_1_3d,
    SUM(CASE WHEN next_diff_minutes IS NOT NULL AND next_diff_minutes > 4320 AND next_diff_minutes <= 10080 THEN 1 ELSE 0 END) * 100 / COUNT(next_diff_minutes) AS second_4_7d,
    SUM(CASE WHEN next_diff_minutes IS NOT NULL AND next_diff_minutes > 10080 THEN 1 ELSE 0 END) * 100 / COUNT(next_diff_minutes) AS second_8d
FROM first_second
GROUP BY time_int;
