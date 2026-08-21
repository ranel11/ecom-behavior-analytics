WITH order_group AS (
    SELECT 
        product_id, 
        avg_price,
        views_product,
        cart_product,
        purchase_product,
        CASE 
            WHEN NTILE(3) OVER (ORDER BY avg_price ASC) = 1 THEN '1. Low' 
            WHEN NTILE(3) OVER (ORDER BY avg_price ASC) = 2 THEN '2. Medium' 
            ELSE '3. High'
        END AS price_group
    FROM dim_products
    WHERE avg_price IS NOT NULL AND avg_price > 0
) 
SELECT 
    price_group,
    ROUND(AVG(avg_price)) AS avg_price_usd,
    ROUND(
        SUM(CASE WHEN cart_product > 0 THEN 1 ELSE 0 END) * 100.0 
        / NULLIF(SUM(CASE WHEN views_product > 0 THEN 1 ELSE 0 END), 0), 
        1
    ) AS percent_views_cart,
    ROUND(
        SUM(CASE WHEN purchase_product > 0 THEN 1 ELSE 0 END) * 100.0 
        / NULLIF(SUM(CASE WHEN cart_product > 0 THEN 1 ELSE 0 END), 0), 
        1
    ) AS percent_purchase_after_cart,
    ROUND(
        SUM(CASE WHEN purchase_product > 0 THEN 1 ELSE 0 END) * 100.0 
        / NULLIF(SUM(CASE WHEN views_product > 0 THEN 1 ELSE 0 END), 0), 
        1
    ) AS percent_purchase_after_views
FROM order_group
GROUP BY price_group
ORDER BY price_group ASC;
