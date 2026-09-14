{{ config(
    materialized='table'
) }}

WITH flattened_cart AS (
    SELECT 
        -- Thông tin đơn hàng (để sau này nối vào bảng Fact)
        stg.order_id,
        stg.user_id,
        stg.event_timestamp,
        
        -- Thông tin sản phẩm sau khi UNNEST và ép kiểu
        SAFE_CAST(item.element.product_id AS INT64) AS product_id,
        COALESCE(
            SAFE_CAST(
                CASE
                    -- Trường hợp 1: Có dấu chấm (hệ US: 1,643.00) -> Xóa dấu phẩy
                    WHEN item.element.price LIKE '%.%' THEN REPLACE(TRIM(item.element.price), ',', '')
                    -- Trường hợp 2: Không có dấu chấm (hệ EU: 288,00) -> Đổi phẩy thành chấm
                    ELSE REPLACE(TRIM(item.element.price), ',', '.')
                END 
            AS FLOAT64)
        , 0.0) AS price,
        SAFE_CAST(item.element.amount AS INT64) AS amount,
        item.element.currency
        
        -- Nếu bạn cần lấy cả option (như size, color), bạn sẽ unnest tiếp ở đây
    FROM {{ ref('checkout_success_stg') }} AS stg,
    UNNEST(stg.cart_products.list) AS item
    WHERE item.element.product_id IS NOT NULL
)

SELECT * FROM flattened_cart  