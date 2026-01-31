-- Fact model for orders
-- Orders fact table with business metrics and dimensional keys
-- Author: Ram Marapally (GitHub: rammarapally)
--
-- Model Purpose:
--   Central fact table for order transactions.
--   Provides comprehensive metrics and dimensions for order analysis.
--   Optimized for efficient analytical queries using Snowflake clustering.
--
-- Key Features:
--   - Incremental materialization for performance
--   - Grain-level definition: One record per order
--   - Dimensional keys linking to dimension tables
--   - Business metrics (amounts, counts, flags)
--   - Snowflake-specific optimizations
--   - SCD Type 2 support via dimensional views
--
-- Grain: One record per order
-- Materialization: Incremental (merge strategy)
-- Update Frequency: Daily
-- Cluster By: order_date, customer_id
-- Last Modified: 2025-01-31

{{
  config(
    materialized = 'incremental',
    unique_key = 'order_id',
    on_schema_change = 'fail',
    incremental_strategy = 'merge',
    cluster_by = ['order_date', 'customer_id'],
    tags = ['daily', 'marts', 'core_fact', 'incremental'],
    post_hook = [
      "{% if execute %} "
      "  ALTER TABLE {{ this }} SET CLUSTERING = (order_date, customer_id) "
      "{% endif %}"
    ]
  )
}}

WITH orders_base AS (
  SELECT
    -- Primary key
    order_id,

    -- Foreign keys (dimensional links)
    customer_id,

    -- Dimensional attributes (denormalized from staging)
    order_number,
    order_status,

    -- Date dimensions
    order_date,
    order_datetime,
    delivery_date,

    -- Base metrics
    order_amount,
    tax_amount,
    shipping_amount,
    total_amount,

    -- Source metadata
    _loaded_at

  FROM {{ ref('stg_orders') }}

  -- Incremental filter: process only new/modified records
  {% if execute and 'incremental' in context %}
    WHERE _loaded_at >= (
      SELECT COALESCE(MAX(_loaded_at), '1900-01-01'::TIMESTAMP)
      FROM {{ this }}
    )
  {% endif %}

)

, order_metrics AS (
  -- Calculate derived metrics and business indicators
  SELECT
    order_id,
    customer_id,
    order_number,
    order_status,

    order_date,
    order_datetime,
    delivery_date,

    -- Base amounts
    order_amount,
    tax_amount,
    shipping_amount,
    total_amount,

    -- Derived metrics
    ROUND((tax_amount / order_amount * 100), 2) AS tax_rate_pct,
    ROUND((shipping_amount / order_amount * 100), 2) AS shipping_rate_pct,
    ROUND((total_amount - order_amount) / total_amount * 100, 2) AS markup_pct,

    -- Business indicators
    CASE
      WHEN order_status IN ('DELIVERED', 'SHIPPED') THEN 1
      ELSE 0
    END AS is_fulfilled_flag,

    CASE
      WHEN order_status = 'CANCELLED' THEN 1
      ELSE 0
    END AS is_cancelled_flag,

    CASE
      WHEN order_status = 'RETURNED' THEN 1
      ELSE 0
    END AS is_returned_flag,

    CASE
      WHEN DATEDIFF('day', order_date, delivery_date) <= 3 THEN 1
      ELSE 0
    END AS is_fast_delivery_flag,

    CASE
      WHEN DATEDIFF('day', order_date, delivery_date) > 7 THEN 1
      ELSE 0
    END AS is_slow_delivery_flag,

    CASE
      WHEN total_amount > 1000 THEN 'high_value'
      WHEN total_amount > 500 THEN 'medium_value'
      ELSE 'standard'
    END AS order_value_category,

    -- Date dimensions (for aggregation)
    YEAR(order_date) AS order_year,
    QUARTER(order_date) AS order_quarter,
    MONTH(order_date) AS order_month,
    WEEK(order_date) AS order_week,
    DAYOFWEEK(order_date) AS order_day_of_week,
    DAY(order_date) AS order_day_of_month,

    -- Delivery dimensions
    YEAR(delivery_date) AS delivery_year,
    MONTH(delivery_date) AS delivery_month,

    -- Lead time calculation
    DATEDIFF('day', order_date, delivery_date) AS delivery_days,

    -- Source metadata
    _loaded_at

  FROM orders_base

)

, final_facts AS (
  SELECT
    -- Primary key
    order_id,

    -- Foreign keys
    customer_id,

    -- Dimensional attributes
    order_number,
    order_status,

    -- Dates
    order_date,
    order_datetime,
    delivery_date,

    -- Core metrics
    order_amount,
    tax_amount,
    shipping_amount,
    total_amount,

    -- Calculated metrics
    tax_rate_pct,
    shipping_rate_pct,
    markup_pct,

    -- Business flags
    is_fulfilled_flag,
    is_cancelled_flag,
    is_returned_flag,
    is_fast_delivery_flag,
    is_slow_delivery_flag,

    -- Categorization
    order_value_category,

    -- Date dimensions
    order_year,
    order_quarter,
    order_month,
    order_week,
    order_day_of_week,
    order_day_of_month,
    delivery_year,
    delivery_month,

    -- Lead time
    delivery_days,

    -- Audit columns
    CURRENT_TIMESTAMP AS dbt_processed_at,
    '{{ target.schema }}' AS dbt_schema,
    '{{ this.name }}' AS dbt_table_name

  FROM order_metrics

)

SELECT *
FROM final_facts
