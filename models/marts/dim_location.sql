WITH checkout_ips AS (
    -- Bước 1: Lấy danh sách các IP duy nhất từ bảng staging để tối ưu hiệu suất JOIN
    SELECT DISTINCT ip
    FROM {{ ref('checkout_success_stg') }}
    WHERE ip IS NOT NULL
),

unique_locations AS (
    -- Bước 2: JOIN với bảng raw.ip2location và lấy các thông tin địa lý độc nhất
    SELECT DISTINCT
        loc.city AS city_name,
        loc.region AS region_name,
        loc.country_code,
        loc.country_name
    FROM checkout_ips req
    JOIN {{ source('glamira_raw', 'ip2location') }} loc
        ON req.ip = loc.ip
)

-- Bước 3: Tạo location_id và thêm các trường audit theo đúng schema đích
SELECT 
    -- Xử lý NULL thành chuỗi rỗng và nối bằng dấu phẩy hoặc gạch đứng
    FARM_FINGERPRINT(
        CONCAT(
            IFNULL(city_name, ''), '|', 
            IFNULL(region_name, ''), '|', 
            IFNULL(country_name, '')
        )
    ) AS location_id,
    
    city_name,
    region_name,
    country_code,
    country_name,
    
    {{ get_audit_columns() }}
    
FROM unique_locations
-- Lọc bỏ các dòng null hoàn toàn (nếu IP không map được ra quốc gia nào)
WHERE country_code IS NOT NULL