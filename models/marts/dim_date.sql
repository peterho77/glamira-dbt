{{ config(
    materialized='table',
    schema='marts_area'
) }}

with date_parts as (
    select * from {{ ref('int_checkout_dates') }}
)

select
    -- Gọi các cột đã xử lý ở layer Intermediate
    date_id,
    cast(day_name as string) as day_name,
    day_of_week,
    day_of_month,
    day_of_year,
    week_of_year,
    month_number,
    cast(month_name as string) as month_name,
    cast(quarter_name as string) as quarter_name,
    quarter_number,
    year_number,
    is_weekend,

    -- Gọi macro sinh 4 cột audit (inserted_date, inserted_by, updated_date, updated_by)
    {{ get_audit_columns() }}

from date_parts