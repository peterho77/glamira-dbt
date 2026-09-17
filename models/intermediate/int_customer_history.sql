{{ config(
    materialized='table'
) }}

WITH source_events AS (
    -- Bước 1: Lấy các trường thông tin khách hàng từ layer Staging
    SELECT
        device_id,
        email_address,
        CAST(user_id AS STRING) AS user_id,
        user_agent,
        event_timestamp AS active_from
    FROM {{ ref('checkout_success_stg') }}
    -- Đảm bảo ít nhất phải có thiết bị hoặc email để định danh
    WHERE device_id IS NOT NULL OR email_address IS NOT NULL
),

deduplicated_events AS (
    -- Bước 2: Loại bỏ các event trùng lặp chính xác tới từng mili-giây của cùng 1 người
    -- (Tránh lỗi window function bị nhân bản dòng)
    SELECT *
    FROM source_events
    QUALIFY ROW_NUMBER() OVER(PARTITION BY email_address, device_id, active_from ORDER BY active_from) = 1
),

state_changes AS (
    -- Bước 3: So sánh trạng thái hiện tại với trạng thái ngay trước đó (LAG)
    SELECT
        device_id,
        email_address,
        user_id,
        user_agent,
        active_from,
        LAG(CONCAT(IFNULL(user_id, ''), '|', IFNULL(user_agent, '')))
            OVER (PARTITION BY email_address, device_id ORDER BY active_from) AS prev_state
    FROM deduplicated_events
),

filtered_changes AS (
    -- Bước 4: Lọc bỏ các event không có sự thay đổi thông tin, chỉ giữ lại các mốc chuyển giao
    SELECT *
    FROM state_changes
    WHERE prev_state IS NULL
       OR CONCAT(IFNULL(user_id, ''), '|', IFNULL(user_agent, '')) != prev_state
),

scd2_logic AS (
    -- Bước 5: Tìm ngày kết thúc (active_to) bằng cách lấy ngày bắt đầu của trạng thái tiếp theo (LEAD)
    SELECT
        device_id,
        email_address,
        user_id,
        user_agent,
        active_from,
        LEAD(active_from) OVER (PARTITION BY email_address, device_id ORDER BY active_from) AS active_to
    FROM filtered_changes
)

SELECT * FROM scd2_logic