# dbt + Snowflake Starter Template

A comprehensive, production-ready dbt starter template for Snowflake data warehouses. This repository provides best practices, examples, and configuration patterns for building scalable data transformation pipelines.

**Author:** Ram Marapally ([GitHub: rammarapally](https://github.com/rammarapally))

## Features

- **Staging Models**: Clean, incremental extraction of raw data from source systems
- **Mart Models**: Dimension and fact tables optimized for analytics
- **Custom Macros**: Schema naming strategies and utility functions
- **Generic Tests**: Data quality tests with custom implementations
- **Snowflake Optimizations**: Incremental models, clustering, and performance considerations
- **Documentation**: Comprehensive YAML schema documentation
- **CI/CD Ready**: Patterns and configurations for automated testing and deployment

## Quick Start

### Prerequisites

- dbt 1.5+ (supports dbt-core and dbt-snowflake)
- Python 3.8+
- Snowflake account with appropriate permissions
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/rammarapally/dbt-snowflake-starter.git
   cd dbt-snowflake-starter
   ```

2. **Install dbt and dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure your Snowflake connection**
   ```bash
   cp profiles.yml.example ~/.dbt/profiles.yml
   ```

   Edit `~/.dbt/profiles.yml` with your Snowflake credentials:
   ```yaml
   dbt_snowflake_starter:
     outputs:
       dev:
         type: snowflake
         account: [your-account-id]
         user: [your-username]
         password: [your-password]
         role: [your-role]
         database: [your-database]
         schema: dbt_dev
         warehouse: [your-warehouse]
         threads: 4
         client_session_keep_alive: False
     target: dev
   ```

4. **Validate the setup**
   ```bash
   dbt debug
   ```

5. **Run the models**
   ```bash
   dbt run
   dbt test
   ```

## Project Structure

```
dbt-snowflake-starter/
├── models/
│   ├── staging/           # Layer 1: Clean, deduplicated raw data
│   │   ├── stg_orders.sql
│   │   └── schema.yml
│   └── marts/             # Layer 2: Business-ready tables
│       ├── dim_customers.sql
│       └── fct_orders.sql
├── macros/
│   └── generate_schema_name.sql
├── tests/
│   └── generic/
│       └── test_not_null_where.sql
├── dbt_project.yml
├── profiles.yml.example
└── README.md
```

## Model Layers

### Staging Models (`models/staging/`)

Staging models are the first transformation layer. They:
- Extract data from raw source tables
- Apply basic cleansing and renaming
- Deduplicate records
- Document data quality expectations
- Use incremental patterns for performance

**Example:** `stg_orders.sql` extracts raw orders with consistent naming conventions and incremental load logic.

### Mart Models (`models/marts/`)

Mart models are the second transformation layer, optimized for analytics:
- **Dimensions** (`dim_*.sql`): Slowly changing dimensions for descriptive attributes
- **Facts** (`fct_*.sql`): Fact tables with grain-level definition and metrics

**Examples:**
- `dim_customers.sql`: Customer dimension with SCD Type 2 (simplified version)
- `fct_orders.sql`: Orders fact table with order metrics

## Key Features

### Incremental Models

Staging models use dbt's incremental pattern to only process new/changed data:

```sql
{{
  config(
    materialized = 'incremental',
    unique_key = 'order_id',
    on_schema_change = 'fail',
    incremental_strategy = 'merge'
  )
}}

SELECT
  order_id,
  customer_id,
  order_date,
  amount
FROM {{ source('raw', 'orders') }}
WHERE 1=1
  {% if execute and 'incremental' in context %}
    AND _dbt_valid_from >= (SELECT MAX(_dbt_valid_from) FROM {{ this }})
  {% endif %}
```

### Snowflake-Specific Optimizations

- **Materialization**: Table and incremental materializations for performance
- **Clustering**: Orders by frequently filtered columns
- **Dynamic SQL**: Efficient data loading patterns
- **Session Parameters**: Optimization flags for Snowflake

### Custom Schema Naming

The `generate_schema_name` macro implements a custom schema naming strategy:

```yaml
# dbt_project.yml
vars:
  custom_schema_logic: true

# Environment: dbt_dev, dbt_staging, dbt_prod
# Models organize into: {database}.{environment}_{model_type}.{table_name}
```

## Testing Strategy

### Built-in Tests

Standard dbt tests included in schema.yml:
- **not_null**: Ensures required fields have values
- **unique**: Validates primary key uniqueness
- **relationships**: Enforces referential integrity
- **accepted_values**: Validates categorical fields

### Custom Generic Tests

`tests/generic/test_not_null_where.sql` - Conditional null checks:
```sql
dbt test --select tag:data_quality
```

## Running dbt

### Basic Commands

```bash
# Run all models
dbt run

# Run specific models
dbt run --select models/staging

# Run models with specific tags
dbt run --select tag:daily

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve

# Create snapshots (for SCD Type 2)
dbt snapshot
```

### Selective Execution

```bash
# Run only staging models
dbt run --select path:models/staging

# Run only models that failed
dbt retry

# Run models and their downstream dependents
dbt run --select +stg_orders+
```

## CI/CD Integration

### dbt Cloud

Integrate with dbt Cloud for automated:
- Development deployments
- Production jobs with schedules
- Automated testing and documentation
- Alerting on failures

### GitHub Actions Example

```yaml
name: dbt CI/CD
on: [push, pull_request]

jobs:
  dbt-run-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.10'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: dbt run
        env:
          DBT_PROFILES_DIR: ./profiles
        run: dbt run --profiles-dir ./profiles
      - name: dbt test
        env:
          DBT_PROFILES_DIR: ./profiles
        run: dbt test --profiles-dir ./profiles
```

## Best Practices Implemented

### 1. **Naming Conventions**
- Staging models: `stg_<source>_<entity>`
- Dimension models: `dim_<entity>`
- Fact models: `fct_<process>`
- Columns: `snake_case`
- Keys: `<entity>_id`, `fact_id`

### 2. **Code Organization**
- Models organized by layer (staging, marts)
- One model per file
- Consistent indentation (2 spaces)
- Clear, self-documenting queries

### 3. **Testing & Validation**
- Every model documented in schema.yml
- Critical columns tested (not null, unique, relationships)
- Custom tests for business logic validation
- Test coverage documented

### 4. **Performance**
- Incremental models for large tables
- Proper indexing with clustering keys
- Efficient SQL leveraging Snowflake features
- Materialization strategy documented per model

### 5. **Documentation**
- Comprehensive YAML schema definitions
- Model descriptions and purposes
- Column-level documentation
- Test documentation
- README files in each directory

## Customization

### Adding New Models

1. Create a new SQL file in appropriate directory
2. Add configuration and jinja templating
3. Document in schema.yml
4. Add tests for critical columns
5. Run `dbt run --select path:models/...`
6. Run `dbt test`

### Modifying Schema Strategy

Edit the `generate_schema_name.sql` macro to customize your schema naming logic based on environment or model type.

### Adding Source Tables

Document sources in `models/staging/schema.yml`:

```yaml
sources:
  - name: raw
    description: "Raw data from operational systems"
    tables:
      - name: orders
        description: "Raw order transactions"
        columns:
          - name: order_id
            description: "Unique order identifier"
            tests:
              - unique
              - not_null
```

## Troubleshooting

### Connection Issues

```bash
# Verify Snowflake connection
dbt debug

# Check profile configuration
cat ~/.dbt/profiles.yml
```

### Model Failures

```bash
# Check compiled SQL
cat target/compiled/dbt_snowflake_starter/models/.../path_to_model.sql

# Run with debug output
dbt run --debug

# Test individually
dbt test --select model_name
```

### Performance Issues

- Check Snowflake query history for long-running queries
- Optimize incremental unique_key selections
- Use clustering keys on large tables
- Consider table materialization for frequently accessed models

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Snowflake Plugin](https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Analytics Engineering Best Practices](https://www.getdbt.com/analytics-engineering/)

## License

This starter template is provided as-is for educational and commercial use.

## Contributing

Contributions are welcome! Please feel free to submit pull requests with improvements, additional examples, or bug fixes.

## Contact

For questions or suggestions, reach out to Ram Marapally on [GitHub](https://github.com/rammarapally).

---

**Last Updated:** January 2025
**dbt Version:** 1.5+
**Snowflake Version:** All current versions
