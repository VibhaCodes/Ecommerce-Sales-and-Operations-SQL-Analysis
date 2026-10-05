use amazon;

#Q1. Find the total number of orders fulfilled by each seller state.

SELECT
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state
ORDER BY total_orders DESC;


#Q2. For each product category, calculate the cumulative revenue generated as orders come in over time.

SELECT
    p.product_category_name,
    o.order_purchase_timestamp,
    oi.price,
    SUM(oi.price) OVER (
        PARTITION BY p.product_category_name
        ORDER BY o.order_purchase_timestamp
    ) AS cumulative_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered';


#Q3. Which payment method do customers use the most, and what is the average order value for each payment type?

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(payment_value), 2) AS average_order_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_orders DESC;


#Q4. Find the customer who has spent the most money across all their orders.

SELECT
    c.customer_unique_id,
    ROUND(SUM(op.payment_value), 2) AS total_spent,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 1;


#Q5. Find the average review score for each product category.

SELECT
    COALESCE(t.product_category_name_english, p.product_category_name) AS category_name,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(r.review_id) AS total_reviews
FROM order_reviews r
JOIN order_items oi ON r.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
GROUP BY category_name
ORDER BY avg_review_score ASC;


#Q6. Find the total number of orders placed by each customer, broken down by the state they live in.

SELECT
    c.customer_state,
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state, c.customer_unique_id;


#Q7. Identify sellers who registered on the platform but have never fulfilled a single order.

select s.seller_id
from sellers s
left join order_items oi on oi.seller_id = s.seller_id
left join orders o on oi.order_id = o.order_id
where o.order_id is NULL;


#Q8. Find the top 5 product categories by total revenue.

SELECT
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;


#Q9. Find the median delivery time (in days) between order placement and actual delivery.

WITH delivery_times AS (
    SELECT
        DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS delivery_days,
        ROW_NUMBER() OVER (
            ORDER BY DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
        ) AS row_num,
        COUNT(*) OVER () AS total_count
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
)
SELECT
    delivery_days AS median_delivery_days
FROM delivery_times
WHERE row_num = ROUND(total_count / 2);


#Q10. Find all products that have never been ordered.

select p.product_id , oi.order_id
from products p
left join order_items oi
on oi.product_id = p.product_id
left join orders o on
o.order_id= oi.order_id
where oi.order_id is NULL;

SELECT p.product_id
from products p
where not EXISTS(
    select 1
    from order_items oi
    where oi.product_id = p.product_id
);

SELECT * from order_items;


#Q11. Find sellers who have fulfilled more orders than the average seller on the platform.

with seller_order_counts as (
    select seller_id,
    count(distinct order_id) as total_orders
    from order_items
    group by seller_id
)

select
seller_id, total_orders
from seller_order_counts
where total_orders >
    (select avg(total_orders)
    from seller_order_counts);


#Q12. Find which Brazilian states have the highest average customer review score for orders delivered there.

select
    c.customer_state,
    avg(orn.review_score) as average_score
from customers c
join orders o
on o.customer_id = c.customer_id
join order_reviews orn
on orn.order_id = o.order_id
WHERE o.order_status = 'delivered'
group by c.customer_state
order by average_score desc
limit 1;


#Q13. Identify customers who have placed orders but never left a review.

SELECT DISTINCT c.customer_id
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM order_reviews r
    WHERE r.order_id = o.order_id
);

SELECT DISTINCT c.customer_id
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
LEFT JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE r.order_id IS NULL;


#Q14. Find the month with the highest number of orders placed across the entire platform.

select DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as order_month,
count(order_id) as total_orders
from orders
group by order_month
order by total_orders desc
limit 1;
