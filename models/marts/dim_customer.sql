{{ config(
    materialized='table',
    unique_key='customer_id'
) }}

WITH customer_history AS (
    SELECT * FROM {{ ref('int_customer_history') }}
)

SELECT
    -- 1. Surrogate Key (Khóa chính): Băm Natural Key kết hợp với mốc thời gian bắt đầu
    FARM_FINGERPRINT(
        CONCAT(
            IFNULL(email_address, ''), '|', 
            IFNULL(device_id, ''), '|', 
            CAST(active_from AS STRING)
        )
    ) AS customer_id,

    -- 2. Natural Key (Khóa nghiệp vụ): Băm tổ hợp định danh email và thiết bị
    FARM_FINGERPRINT(
        CONCAT(
            IFNULL(email_address, ''), '|', 
            IFNULL(device_id, '')
        )
    ) AS customer_nk,

    -- 3. Thông tin chi tiết khách hàng
    user_id,
    device_id,
    user_agent,
    email_address,

    -- 4. Trạng thái SCD Type 2
    CASE WHEN active_to IS NULL THEN TRUE ELSE FALSE END AS flag_current,
    CAST(active_from AS DATETIME) AS active_from,
    CAST(active_to AS DATETIME) AS active_to,

    -- 5. Các cột Audit hệ thống
    CURRENT_DATE() AS inserted_date,
    'stevenho' AS inserted_by,
    CURRENT_DATE() AS updated_date,
    'stevenho' AS updated_by

FROM customer_history