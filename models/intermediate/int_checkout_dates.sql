{{ config(
    materialized='table',
    schema='intermediate_area'
) }}

with staging_events as (
    -- Lấy dữ liệu từ bảng Staging của bạn
    select * from {{ ref('checkout_success_stg') }}
),

unique_dates as (
    -- Trích xuất phần "Ngày" (Date) từ cột Timestamp và loại bỏ các ngày trùng lặp
    select distinct
        extract(date from event_timestamp) as raw_date
    from staging_events
    where event_timestamp is not null
),

extracted_parts as (
    select
        -- Khóa chính date_id dạng INT (Ví dụ: 20240905)
        cast(format_date('%Y%m%d', raw_date) as int64) as date_id,
        
        -- Các thành phần ngày
        format_date('%A', raw_date) as day_name,
        extract(dayofweek from raw_date) as day_of_week, -- 1 = Chủ nhật, 7 = Thứ bảy
        extract(day from raw_date) as day_of_month,
        extract(dayofyear from raw_date) as day_of_year,
        
        -- Các thành phần tuần và tháng
        extract(isoweek from raw_date) as week_of_year,
        extract(month from raw_date) as month_number,
        format_date('%B', raw_date) as month_name,
        
        -- Các thành phần quý và năm
        concat('Q', extract(quarter from raw_date)) as quarter_name,
        extract(quarter from raw_date) as quarter_number,
        extract(year from raw_date) as year_number,
        
        -- Cờ đánh dấu cuối tuần
        case 
            when extract(dayofweek from raw_date) in (1, 7) then true 
            else false 
        end as is_weekend

    from unique_dates
)

select * from extracted_parts