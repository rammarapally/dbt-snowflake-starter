{#
  Custom schema naming macro for dbt-snowflake-starter
  Author: Ram Marapally (GitHub: rammarapally)

  Purpose:
    Implements dynamic schema naming strategy based on environment and model tier.
    Enables proper schema separation for dev/staging/prod environments.

  Strategy:
    - Development: {database}.dbt_dev_{model_type}
    - Staging: {database}.dbt_staging_{model_type}
    - Production: {database}.dbt_prod_{model_type}

  Model Types:
    - staging: For staging layer models
    - marts: For marts layer models
    - tests: For data quality tests
    - snapshots: For snapshot tables
    - default: Generic models

  Usage:
    Enabled via dbt_project.yml:
      vars:
        custom_schema_logic: true

  Example Outputs:
    dev environment: my_database.dbt_dev_staging, my_database.dbt_dev_marts
    prod environment: my_database.dbt_prod_staging, my_database.dbt_prod_marts
#}

{%- macro generate_schema_name(custom_schema_name, node) -%}

  {%- set custom_schema_logic = var('custom_schema_logic', false) -%}

  {%- if not custom_schema_logic -%}
    {# Use default dbt behavior if custom logic disabled #}
    {% if custom_schema_name is none %}
      {{ target.schema }}
    {%- else -%}
      {{ custom_schema_name }}
    {%- endif -%}

  {%- else -%}
    {# Custom schema naming logic #}

    {%- set environment = target.name | lower -%}

    {# Determine schema suffix based on node path #}
    {%- set schema_suffix = 'default' -%}

    {%- if 'staging' in node.path -%}
      {%- set schema_suffix = 'staging' -%}
    {%- elif 'marts' in node.path -%}
      {%- set schema_suffix = 'marts' -%}
    {%- elif 'snapshots' in node.path -%}
      {%- set schema_suffix = 'snapshots' -%}
    {%- elif 'seeds' in node.path -%}
      {%- set schema_suffix = 'seeds' -%}
    {%- elif 'analysis' in node.path -%}
      {%- set schema_suffix = 'analysis' -%}
    {%- endif -%}

    {# Build schema name with environment and suffix #}
    {%- if environment == 'dev' -%}
      dbt_dev_{{ schema_suffix }}
    {%- elif environment == 'staging' -%}
      dbt_staging_{{ schema_suffix }}
    {%- elif environment == 'prod' -%}
      dbt_prod_{{ schema_suffix }}
    {%- else -%}
      dbt_{{ environment }}_{{ schema_suffix }}
    {%- endif -%}

  {%- endif -%}

{%- endmacro %}

{#
  Macro: set_query_tag
  Purpose: Sets query tag in Snowflake for query tracking and cost attribution

  Query tags help identify:
    - Which model is running
    - Which environment is executing
    - Test vs production runs
#}

{%- macro set_query_tag() -%}
  {%- set query_tag = 'dbt_' ~ target.name ~ '_' ~ this.name -%}
  ALTER SESSION SET QUERY_TAG = '{{ query_tag }}';
{%- endmacro -%}

{#
  Macro: unset_query_tag
  Purpose: Clears the query tag after model execution
#}

{%- macro unset_query_tag() -%}
  ALTER SESSION SET QUERY_TAG = NULL;
{%- endmacro -%}

{#
  Macro: get_incremental_days
  Purpose: Returns the number of days to look back for incremental models

  Arguments:
    - max_days: Maximum number of days to look back (default: 7)

  Returns:
    - Number of days to filter in incremental models

  Usage in models:
    WHERE _loaded_at >= CURRENT_DATE - {{ get_incremental_days(14) }}
#}

{%- macro get_incremental_days(max_days=7) -%}
  {%- set lookback_days = var('incremental_lookback_days', max_days) -%}
  {{ lookback_days }}
{%- endmacro -%}

{#
  Macro: create_monthly_snapshot
  Purpose: Creates a monthly snapshot identifier from a date

  Arguments:
    - date_column: Column name or expression returning a DATE

  Returns:
    - YYYYMM format for monthly grouping
#}

{%- macro create_monthly_snapshot(date_column) -%}
  TO_CHAR({{ date_column }}, 'YYYYMM')::INT
{%- endmacro -%}

{#
  Macro: cast_numeric_safe
  Purpose: Safely casts a value to NUMERIC(18,2), defaulting to 0 on failure

  Arguments:
    - column: Column or expression to cast
    - precision: Precision (default: 18)
    - scale: Scale (default: 2)

  Returns:
    - NUMERIC value or 0
#}

{%- macro cast_numeric_safe(column, precision=18, scale=2) -%}
  COALESCE(
    TRY_CAST({{ column }} AS NUMERIC({{ precision }}, {{ scale }})),
    0.00
  )
{%- endmacro -%}

{#
  Macro: get_date_spine
  Purpose: Generates a date spine for joining with fact tables

  Arguments:
    - start_date: First date to generate (can be column reference)
    - end_date: Last date to generate (can be column reference)

  Returns:
    - CTE with date_day column containing consecutive dates
#}

{%- macro get_date_spine(start_date, end_date) -%}
  dates AS (
    SELECT
      DATEADD('day', ROW_NUMBER() OVER (ORDER BY NULL) - 1, {{ start_date }}) AS date_day

    FROM TABLE(GENERATOR(ROWCOUNT => DATEDIFF('day', {{ start_date }}, {{ end_date }}) + 1)))
{%- endmacro -%}
