{{ config(
    materialized='table',
    unique_key='product_id'
) }}

WITH aggregated_products AS (
    -- Lấy dữ liệu từ bảng Intermediate vừa tạo và tìm mức giá
    SELECT
        product_id,
        MAX(price) AS base_price, 
        MAX(price) AS max_price,
        MIN(price) AS min_price
    FROM {{ ref('int_checkout_cart_items') }}
    GROUP BY product_id
)

SELECT
    product_id,
    
    CAST(NULL AS STRING) AS product_name, 
    CAST(NULL AS STRING) AS product_code, 
    
    base_price,
    max_price,
    min_price,
    
    TRUE AS flag_current,
    CURRENT_DATETIME() AS active_from,
    CAST(NULL AS DATETIME) AS active_to,
    
    {{ get_audit_columns() }}

FROM aggregated_products