{% macro get_audit_columns() %}
    -- Lấy thời điểm job dbt bắt đầu chạy
    cast('{{ run_started_at }}' as timestamp) as inserted_date,
    
    -- Lấy tên User/Service Account đang thực thi dbt (được cấu hình trong profiles.yml)
    '{{ target.user }}' as inserted_by,
    
    cast('{{ run_started_at }}' as timestamp) as updated_date,
    '{{ target.user }}' as updated_by
{% endmacro %}