-- Kiểm tra xem có customer_nk nào đang sở hữu nhiều hơn 1 dòng có cờ flag_current = TRUE hay không
WITH active_records AS (
    SELECT 
        customer_nk,
        COUNT(*) as active_count
    FROM {{ ref('dim_customer') }}
    WHERE flag_current = TRUE
    GROUP BY customer_nk
)

SELECT *
FROM active_records
WHERE active_count > 1