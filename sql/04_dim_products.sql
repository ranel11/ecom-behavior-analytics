CREATE TABLE dim_products as 
SELECT product_id, MAX(category_id) as category_id , MAX(COALESCE(brand, 'Unknown')) AS brand, 
count(DISTINCT(user_id)) as unique_users,
sum(CASE WHEN event_type ='view' then 1 ELSE 0 END) as views_product,
sum(CASE WHEN event_type ='cart' then 1 ELSE 0 END) as cart_product,
sum(CASE WHEN event_type ='purchase' then 1 ELSE 0 END) as purchase_product,
avg(CASE WHEN event_type ='purchase' then price end) as avg_price,
max(CASE WHEN event_type ='purchase' then price end) as max_price,
min(CASE WHEN event_type ='purchase' then price end) as min_price,
sum(CASE WHEN event_type ='purchase' then price else 0 end) as product_revenue
FROM events 
GROUP BY product_id
