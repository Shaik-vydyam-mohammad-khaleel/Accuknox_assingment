-- 1. Create a temporary 'sales_data' table for demonstration
CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,
    user_id INTEGER,
    order_date DATE,
    amount DECIMAL(10, 2)
);

-- 2. Complex Query: Monthly Cohort Retention
-- We use CTEs (WITH clauses) to break down complex logic into readable steps.

WITH UserFirstPurchase AS (
    -- Identify the 'Birth Month' for every user
    SELECT 
        user_id,
        MIN(strftime('%Y-%m-01', order_date)) AS cohort_month
    FROM orders
    GROUP BY user_id
),
UserActivity AS (
    -- Join activity back to their cohort month
    SELECT
        o.user_id,
        u.cohort_month,
        strftime('%Y-%m-01', o.order_date) AS activity_month,
        -- Calculate the month index (0 = first month, 1 = second month, etc.)
        (julianday(strftime('%Y-%m-01', o.order_date)) - julianday(u.cohort_month)) / 30 AS month_index
    FROM orders o
    JOIN UserFirstPurchase u ON o.user_id = u.user_id
)
-- 3. Final Output: Calculate retention percentage per cohort
SELECT 
    cohort_month,
    month_index,
    COUNT(DISTINCT user_id) AS active_users,
    -- Window Function to get the original size of the cohort for percentage calculation
    FIRST_VALUE(COUNT(DISTINCT user_id)) OVER (PARTITION BY cohort_month ORDER BY month_index) AS cohort_size,
    ROUND(CAST(COUNT(DISTINCT user_id) AS FLOAT) * 100 / 
          FIRST_VALUE(COUNT(DISTINCT user_id)) OVER (PARTITION BY cohort_month ORDER BY month_index), 2) || '%' AS retention_rate
FROM UserActivity
GROUP BY cohort_month, month_index
ORDER BY cohort_month, month_index;