{#
  Custom Generic Test: not_null_where
  Author: Ram Marapally (GitHub: rammarapally)

  Purpose:
    Tests that a column is not null for rows matching a specific WHERE condition.
    Extends dbt's built-in not_null test to support conditional validation.

  This is useful for:
    - Testing columns that may be null under certain conditions
    - Validating required fields for specific order statuses
    - Checking non-null constraints for specific date ranges
    - Conditional data quality checks based on business logic

  Arguments:
    - column_name (required): Column to test for null values
    - where (optional): WHERE clause to filter rows. Default: "1=1" (all rows)

  Example Usage in schema.yml:
    columns:
      - name: delivery_date
        tests:
          - not_null_where:
              where: "order_status = 'DELIVERED'"

    - name: cancellation_reason
        tests:
          - not_null_where:
              where: "order_status = 'CANCELLED'"

    - name: customer_id
        tests:
          - not_null_where:
              where: "order_status NOT IN ('DRAFT', 'CANCELLED')"

  Returns:
    - Passes if all non-null rows match the WHERE condition
    - Fails if any matching rows have null values in the specified column

  Implementation Details:
    - Uses standard dbt test pattern with SQL query
    - Snowflake-optimized for performance
    - Returns rows that fail the test (null values in matching WHERE clause)
    - Test passes if query returns 0 rows
#}

{% test not_null_where(model, column_name, where="1=1") %}

  {# Validate inputs #}
  {% if column_name is none %}
    {{ exceptions.raise_compiler_error("not_null_where test requires 'column_name' argument") }}
  {% endif %}

  SELECT
    *

  FROM {{ model }}

  WHERE
    {# Main condition: column is null #}
    {{ column_name }} IS NULL
    {# AND clause: only check rows matching the WHERE condition #}
    AND ({{ where }})

  LIMIT 100

{% endtest %}

{#
  Additional Helper Tests
#}

{#
  Custom Generic Test: expression_is_true
  Purpose: Tests that a SQL expression evaluates to true for all rows

  Example Usage:
    - name: total_amount
      tests:
        - expression_is_true:
            expression: "total_amount = order_amount + tax_amount + shipping_amount"

    - name: order_date
      tests:
        - expression_is_true:
            expression: "order_date <= CURRENT_DATE()"

  Returns:
    - Passes if expression is true for all rows
    - Fails if any rows have expression = false
#}

{% test expression_is_true(model, expression) %}

  {# Validate inputs #}
  {% if expression is none %}
    {{ exceptions.raise_compiler_error("expression_is_true test requires 'expression' argument") }}
  {% endif %}

  SELECT
    *

  FROM {{ model }}

  WHERE NOT ({{ expression }})

  LIMIT 100

{% endtest %}

{#
  Custom Generic Test: consecutive_not_null
  Purpose: Tests that consecutive rows have non-null values for a column

  Useful for:
    - Verifying data continuity across time periods
    - Checking for data gaps in daily records

  Arguments:
    - column_name: Column to check
    - order_by: Column(s) to order results (required for consecutive check)

  Example Usage:
    - name: transaction_amount
      tests:
        - consecutive_not_null:
            order_by: "transaction_date"
#}

{% test consecutive_not_null(model, column_name, order_by) %}

  {# Validate inputs #}
  {% if column_name is none or order_by is none %}
    {{ exceptions.raise_compiler_error("consecutive_not_null test requires 'column_name' and 'order_by' arguments") }}
  {% endif %}

  WITH ordered_data AS (
    SELECT
      {{ column_name }},
      LAG({{ column_name }}) OVER (ORDER BY {{ order_by }}) AS prev_{{ column_name }},
      ROW_NUMBER() OVER (ORDER BY {{ order_by }}) AS row_num

    FROM {{ model }}
  )

  SELECT
    *

  FROM ordered_data

  WHERE
    {# Check if current or previous value is null, creating a gap #}
    ({{ column_name }} IS NULL OR prev_{{ column_name }} IS NULL)
    AND row_num > 1

  LIMIT 100

{% endtest %}

{#
  Custom Generic Test: relationships_where
  Purpose: Tests referential integrity with conditional checking

  Like dbt's relationships test but with a WHERE condition to limit scope.

  Arguments:
    - column_name: Foreign key column
    - to: Model or source reference
    - field: Primary key field in target model
    - where: Optional WHERE clause for conditional checking

  Example Usage:
    - name: customer_id
      tests:
        - relationships_where:
            to: ref('dim_customers')
            field: customer_id
            where: "order_status != 'DRAFT'"
#}

{% test relationships_where(model, column_name, to, field, where="1=1") %}

  {# Validate inputs #}
  {% if column_name is none or to is none or field is none %}
    {{ exceptions.raise_compiler_error("relationships_where test requires column_name, to, and field arguments") }}
  {% endif %}

  SELECT
    source.{{ column_name }}

  FROM {{ model }} AS source

  WHERE
    {# Only check rows matching WHERE clause #}
    ({{ where }})
    {# Check that the foreign key exists in target table #}
    AND source.{{ column_name }} IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM {{ to }} AS target
      WHERE source.{{ column_name }} = target.{{ field }}
    )

  LIMIT 100

{% endtest %}

{#
  Custom Generic Test: uniqueness_with_conditions
  Purpose: Tests column uniqueness under specific conditions

  Example Usage:
    - name: order_id
      tests:
        - uniqueness_with_conditions:
            where: "order_status != 'CANCELLED'"

    - name: email
      tests:
        - uniqueness_with_conditions:
            where: "email IS NOT NULL AND customer_status = 'ACTIVE'"
#}

{% test uniqueness_with_conditions(model, column_name, where="1=1") %}

  {# Validate inputs #}
  {% if column_name is none %}
    {{ exceptions.raise_compiler_error("uniqueness_with_conditions test requires 'column_name' argument") }}
  {% endif %}

  SELECT
    {{ column_name }},
    COUNT(*) AS occurrences

  FROM {{ model }}

  WHERE
    {# Only count rows matching WHERE clause #}
    ({{ where }})
    {# Exclude nulls from uniqueness check #}
    AND {{ column_name }} IS NOT NULL

  GROUP BY {{ column_name }}

  HAVING COUNT(*) > 1

  LIMIT 100

{% endtest %}
