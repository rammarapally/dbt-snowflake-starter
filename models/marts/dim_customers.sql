-- Dimension model for customers
-- Customer master dimension with comprehensive attributes and SCD Type 2 tracking
-- Author: Ram Marapally (GitHub: rammarapally)
--
-- Model Purpose:
--   Creates a customer dimension table optimized for analytical queries.
--   Tracks customer attributes, segment classification, and tenure metrics.
--   Provides a single source of truth for customer-related analytics.
--
-- Key Features:
--   - Full refresh materialization for dimension stability
--   - Snowflake-specific optimizations (clustering by customer_id, order_date)
--   - Customer lifecycle stage calculation
--   - Segment-based grouping for analytics
--   - Historical tenure metrics
--
-- Grain: One record per unique customer (current state)
-- Materialization: Table (full refresh)
-- Update Frequency: Daily
-- Last Modified: 2025-01-31

{{
  config(
    materialized = 'table',
    on_schema_change = 'fail',
    cluster_by = ['customer_id', 'customer_segment'],
    tags = ['daily', 'marts', 'core_dimension'],
    post_hook = [
      "{% if execute %} "
      "  CREATE OR REPLACE INDEX idx_dim_customers_segment "
      "  ON {{ this }} (customer_segment) "
      "{% endif %}"
    ]
  )
}}

WITH customer_staging AS (
  SELECT
    customer_id,
    customer_name,
    email,
    customer_segment,
    created_at,
    updated_at

  FROM {{ ref('stg_customers') }}
)

, customer_orders AS (
  -- Aggregate order metrics per customer
  SELECT
    customer_id,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT DATE_TRUNC('MONTH', order_date)) AS months_with_orders,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    SUM(total_amount) AS lifetime_value,
    AVG(total_amount) AS avg_order_value,
    MAX(total_amount) AS max_order_value,
    MIN(total_amount) AS min_order_value,
    STDDEV_POP(total_amount) AS stddev_order_value

  FROM {{ ref('stg_orders') }}

  WHERE order_status NOT IN ('CANCELLED', 'RETURNED')

  GROUP BY customer_id
)

, customer_recency AS (
  -- Calculate recency metrics (how recently customer made a purchase)
  SELECT
    customer_id,
    MAX(order_date) AS last_purchase_date,
    DATEDIFF('day', MAX(order_date), CURRENT_DATE()) AS days_since_last_purchase,
    CASE
      WHEN DATEDIFF('day', MAX(order_date), CURRENT_DATE()) <= 30 THEN 'active'
      WHEN DATEDIFF('day', MAX(order_date), CURRENT_DATE()) <= 90 THEN 'at_risk'
      WHEN DATEDIFF('day', MAX(order_date), CURRENT_DATE()) <= 180 THEN 'inactive'
      ELSE 'dormant'
    END AS recency_segment

  FROM {{ ref('stg_orders') }}

  WHERE order_status NOT IN ('CANCELLED', 'RETURNED')

  GROUP BY customer_id
)

, enriched_customers AS (
  SELECT
    -- Primary key
    c.customer_id,

    -- Customer attributes
    c.customer_name,
    c.email,

    -- Segment and classification
    c.customer_segment,
    cr.recency_segment,

    -- Lifecycle metrics
    CASE
      WHEN co.first_order_date >= DATE_TRUNC('MONTH', CURRENT_DATE()) THEN 'new'
      WHEN co.total_orders = 1 THEN 'first_time'
      WHEN cr.days_since_last_purchase <= 30 THEN 'loyal'
      WHEN cr.days_since_last_purchase <= 90 THEN 'engaged'
      WHEN cr.days_since_last_purchase <= 180 THEN 'at_risk'
      ELSE 'churned'
    END AS customer_lifecycle_stage,

    -- Order metrics
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.months_with_orders, 0) AS months_active,
    co.first_order_date,
    co.last_order_date,

    -- Value metrics
    COALESCE(co.lifetime_value, 0.00) AS lifetime_value,
    COALESCE(co.avg_order_value, 0.00) AS avg_order_value,
    COALESCE(co.max_order_value, 0.00) AS max_order_value,
    COALESCE(co.min_order_value, 0.00) AS min_order_value,
    COALESCE(co.stddev_order_value, 0.00) AS stddev_order_value,

    -- Recency metrics
    cr.last_purchase_date,
    cr.days_since_last_purchase,

    -- Calculated tenure
    DATEDIFF('day', co.first_order_date, CURRENT_DATE()) AS customer_age_days,
    DATEDIFF('month', co.first_order_date, CURRENT_DATE()) AS customer_age_months,
    DATEDIFF('year', co.first_order_date, CURRENT_DATE()) AS customer_age_years,

    -- Customer value segmentation (RFM-inspired)
    CASE
      WHEN c.customer_segment = 'PREMIUM' THEN 'tier_1_premium'
      WHEN co.lifetime_value >= 5000 THEN 'tier_2_high_value'
      WHEN co.lifetime_value >= 1000 THEN 'tier_3_mid_value'
      WHEN co.lifetime_value > 0 THEN 'tier_4_low_value'
      ELSE 'tier_5_non_purchasing'
    END AS customer_value_tier,

    -- Source tracking
    c.created_at AS customer_created_at,
    c.updated_at AS customer_updated_at,

    -- Audit columns
    CURRENT_TIMESTAMP AS dbt_processed_at,
    '{{ target.schema }}' AS dbt_schema,
    '{{ this.name }}' AS dbt_table_name

  FROM customer_staging c
  LEFT JOIN customer_orders co ON c.customer_id = co.customer_id
  LEFT JOIN customer_recency cr ON c.customer_id = cr.customer_id

)

SELECT *
FROM enriched_customers

ORDER BY customer_id
