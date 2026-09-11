{{ config(
    materialized='incremental',
    unique_key='order_id',
    merge_exclude_columns=['inserted_date', 'inserted_by'] 
) }}

with raw_source as (
    select * from {{ source('glamira_raw', 'checkout_success') }}
    
    {% if is_incremental() %}
        -- Lọc dữ liệu mới ngay từ CTE để giảm dung lượng xử lý cho hàm cửa sổ bên dưới
        where timestamp_millis(time_stamp) > (select max(updated_date) from {{ this }})
    {% endif %}
)

select
    -- 1. Đổi tên cột chuẩn mực
    -- Chuyển chuỗi "5.0" -> Số thực 5.0 -> Số nguyên 5
    SAFE_CAST(SAFE_CAST(user_id_db AS FLOAT64) AS INT64) as user_id,
    SAFE_CAST(SAFE_CAST(order_id AS FLOAT64) AS INT64) as order_id,
    SAFE_CAST(SAFE_CAST(store_id AS FLOAT64) AS INT64) as store_id,

    -- 2. Ép kiểu dữ liệu (Sử dụng cú pháp của BigQuery)
    timestamp_millis(time_stamp) as event_timestamp, 
    cast(local_time as timestamp) as local_timestamp,
    cast(show_recommendation as boolean) as is_recommendation_shown,

    -- 3. Giữ nguyên các chuỗi thông tin định danh và thuộc tính
    ip,
    user_agent,
    resolution,
    device_id,
    api_version,
    current_url,
    referrer_url,
    email_address,

    -- 4. Giữ nguyên dữ liệu RECORD để unnest ở layer sau
    cart_products,

    {{ get_audit_columns() }}

from raw_source
-- 5. Loại bỏ trùng lặp
-- Phân nhóm theo order_id, sắp xếp theo time_stamp giảm dần (desc) và chỉ lấy dòng đầu tiên (số 1)
QUALIFY row_number() over (partition by order_id order by time_stamp desc) = 1