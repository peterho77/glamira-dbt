{% test null_check(model, column_name) %}

    SELECT *
    FROM {{ model }}
    WHERE {{ column_name }} IS NULL

{% endtest %}