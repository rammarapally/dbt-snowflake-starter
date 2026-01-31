-- Staging model for orders
-- Extracts and transforms raw order data with incremental refresh
-- Author: Ram Marapally (GitHub: rammarapally)
--
-- Model Purpose:
--   Cleans and standardizes raw order data from the source system.
--   Applies incremental loading for performance optimization.
--   Removes duplicates and standardizes column names.
--
-- Key Features:
--   - Incremental materialization using MERGE strategy
--   - Efficient change detection using _dbt_valid_from timestamp
--   - Data quality validation via dbt tests
--   - Snowflake-specific optimizations (clustering, pruning)
--
-- Grain: One record per order
-- Last Modified: 2025-01-31

{{
  config(
    materialized = 'incremental',
    unique_key = 'order_id',
    on_schema_change = 'fail',
    incremental_strategy = 'merge',
    -- Snowflake-specific configurations
    cluster_by = ['order_date', 'customer_id'],
    tags = ['daily', 'critical'],
    post_hook = [
      "{% if execute %} "
      "  ALTER TABLE {{ this }} SET CLUSTERING = (order_date, customer_id) "
      "{% endif %}"
    ]
  )
}}

WITH source_data AS (
  SELECT
    -- Primary key
    order_id,

    -- Foreign keys
    customer_id,

    -- Business keys
    order_number,
    order_status,

    -- Dimensional attributes
    order_date,
    order_datetime,
    delivery_date,

    -- Metrics
    order_amount,
    tax_amount,
    shipping_amount,
    total_amount,

    -- Metadata fields
    CAST(_loaded_at AS TIMESTAMP) AS _loaded_at,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS dbt_created_at

  FROM {{ source('raw', 'orders') }}

  -- Incremental filter: only process new or modified records
  {% if execute and 'incremental' in context %}
    WHERE _loaded_at >= (
      SELECT COALESCE(MAX(_loaded_at), '1900-01-01'::TIMESTAMP)
      FROM {{ this }}
    )
  {% endif %}

)

-- Deduplication step: keep the most recent version of each order
, deduplicated AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY _loaded_at DESC) AS rn

  FROM source_data
)

-- Final transformation: clean and standardize
, transformed AS (
  SELECT
    order_id,
    customer_id,
    order_number,
    UPPER(order_status) AS order_status,

    -- Convert date fields to DATE type for consistency
    CAST(order_date AS DATE) AS order_date,
    CAST(order_datetime AS TIMESTAMP) AS order_datetime,
    CAST(delivery_date AS DATE) AS delivery_date,

    -- Cast monetary amounts to NUMERIC(18,2) for precision
    CAST(order_amount AS NUMERIC(18, 2)) AS order_amount,
    CAST(tax_amount AS NUMERIC(18, 2)) AS tax_amount,
    CAST(shipping_amount AS NUMERIC(18, 2)) AS shipping_amount,
    CAST(total_amount AS NUMERIC(18, 2)) AS total_amount,

    -- Calculate derived metrics
    CASE
      WHEN total_amount < 0 THEN 'negative'
      WHEN total_amount = 0 THEN 'zero'
      WHEN total_amount <= 100 THEN 'small'
      WHEN total_amount <= 500 THEN 'medium'
      ELSE 'large'
    END AS order_size_category,

    -- Metadata and audit columns
    _loaded_at,
    dbt_created_at,
    CURRENT_TIMESTAMP AS dbt_processed_at,
    '{{ target.schema }}' AS dbt_schema,
    '{{ this.name }}' AS dbt_table_name

  FROM deduplicated
  WHERE rn = 1  -- Keep only the latest version

)

SELECT *
FROM transformed
