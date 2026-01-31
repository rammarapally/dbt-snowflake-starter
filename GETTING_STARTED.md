# Getting Started with dbt-Snowflake-Starter

**Author:** Ram Marapally (GitHub: rammarapally)
**Last Updated:** January 2025

A quick-start guide to get up and running with this dbt and Snowflake starter template.

## Prerequisites

Before you begin, ensure you have:

- **Python 3.8+** installed ([Download Python](https://www.python.org/))
- **Git** installed ([Download Git](https://git-scm.com/))
- **Snowflake Account** with:
  - Active user account with appropriate permissions
  - A database where you can create schemas
  - A warehouse (or the ability to create one)
  - A role assigned with necessary privileges

## Step 1: Clone the Repository

```bash
git clone https://github.com/rammarapally/dbt-snowflake-starter.git
cd dbt-snowflake-starter
```

## Step 2: Create a Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

## Step 3: Install Dependencies

```bash
pip install -q -r requirements.txt
```

This installs:
- dbt-core and dbt-snowflake
- dbt packages (dbt-utils, dbt-expectations)
- Development tools (pytest, black, mypy)
- Data tools (pandas, numpy)

## Step 4: Configure Snowflake Connection

### Option A: Using profiles.yml (Recommended for Development)

1. **Copy the example profile**
   ```bash
   cp profiles.yml.example ~/.dbt/profiles.yml
   ```

2. **Edit the configuration**
   ```bash
   # macOS/Linux
   nano ~/.dbt/profiles.yml

   # or open in your editor
   code ~/.dbt/profiles.yml
   ```

3. **Replace placeholder values**
   ```yaml
   dbt_snowflake_starter:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: xy12345.us-east-1          # Your Snowflake account ID
         user: your_username                  # Your Snowflake username
         password: your_password              # Your Snowflake password
         database: analytics_dev              # Your dev database
         schema: dbt_dev
         warehouse: compute_wh                # Your warehouse name
         role: analytics_dev_role             # Your role name
         threads: 4
         client_session_keep_alive: false
   ```

### Option B: Using Environment Variables (Recommended for CI/CD)

```bash
# Set Snowflake credentials as environment variables
export SNOWFLAKE_ACCOUNT=xy12345.us-east-1
export SNOWFLAKE_USER=your_username
export SNOWFLAKE_PASSWORD=your_password
export SNOWFLAKE_DATABASE=analytics_dev
export SNOWFLAKE_WAREHOUSE=compute_wh
export SNOWFLAKE_ROLE=analytics_dev_role
```

## Step 5: Verify Your Connection

```bash
dbt debug
```

Expected output:
```
All checks passed!
```

If you see errors, check:
- Snowflake account ID format (should be like: xy12345.us-east-1)
- Username and password are correct
- Database exists and you have access
- Warehouse is active
- Role has appropriate permissions

## Step 6: Run Your First Models

```bash
# Run all models
dbt run

# Run specific models
dbt run --select models/staging

# Run with specific number of threads
dbt run --threads 8
```

Expected output shows:
- Timing for each model
- Success/failure status
- Number of rows created/updated

## Step 7: Run Data Quality Tests

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select stg_orders

# Run only failing tests
dbt retry
```

Expected output shows:
- Each test that ran
- Pass/fail status
- Number of records failing (if applicable)

## Step 8: Generate Documentation

```bash
# Generate documentation
dbt docs generate

# Serve documentation locally
dbt docs serve
```

Visit `http://localhost:8000` to explore:
- Data lineage and dependencies
- Model descriptions and column details
- Test coverage and results
- Source definitions

Press `Ctrl+C` to stop the documentation server.

## Step 9: Explore the Structure

Take time to review:

```bash
# View the staging model
cat models/staging/stg_orders.sql

# View the dimension model
cat models/marts/dim_customers.sql

# View the fact model
cat models/marts/fct_orders.sql

# View schema documentation
cat models/staging/schema.yml

# View custom macros
cat macros/generate_schema_name.sql

# View custom tests
cat tests/generic/test_not_null_where.sql
```

## Common Commands

### Development Workflow

```bash
# Run and test in one command
dbt run && dbt test

# Run with debug output
dbt run --debug

# Run specific model and dependents
dbt run --select +stg_orders

# Run with fresh state (re-run all)
dbt run --full-refresh

# Test before running
dbt test --models stg_orders
dbt run --select stg_orders
```

### Documentation and Inspection

```bash
# View compiled SQL
cat target/compiled/dbt_snowflake_starter/models/staging/stg_orders.sql

# View run results
cat target/run_results.json

# View manifest (includes lineage)
cat target/manifest.json
```

### Maintenance

```bash
# Clean dbt artifacts
dbt clean

# Parse and validate without running
dbt parse

# Snapshot (if using SCD Type 2)
dbt snapshot

# Seeds (if using CSV data)
dbt seed

# Install packages
dbt deps
```

## Understanding the Architecture

### Three-Layer Architecture

1. **Raw** → Raw data from source systems
   - Location: `{{ source('raw', 'orders') }}`
   - Not modeled by dbt

2. **Staging** → Cleaned, deduplicated data
   - Location: `models/staging/`
   - Naming: `stg_<source>_<entity>`
   - Example: `stg_orders`, `stg_customers`
   - Materialization: Incremental (for performance)

3. **Marts** → Analysis-ready tables
   - Location: `models/marts/`
   - Dimensions: `dim_<entity>` (e.g., dim_customers)
   - Facts: `fct_<process>` (e.g., fct_orders)
   - Materialization: Table or Incremental

### Key Files to Review

- `dbt_project.yml` - Project configuration
- `models/staging/schema.yml` - Source and model documentation
- `macros/generate_schema_name.sql` - Custom utilities
- `.github/workflows/dbt_ci.yml` - CI/CD pipeline
- `REPOSITORY_STRUCTURE.md` - Detailed file descriptions

## Next Steps: Add Your Own Models

### 1. Create a New Staging Model

```sql
-- models/staging/stg_products.sql
{{
  config(
    materialized = 'incremental',
    unique_key = 'product_id',
    on_schema_change = 'fail',
    incremental_strategy = 'merge'
  )
}}

SELECT
  product_id,
  product_name,
  category,
  price,
  CURRENT_TIMESTAMP AS dbt_created_at

FROM {{ source('raw', 'products') }}

{% if execute and 'incremental' in context %}
  WHERE _loaded_at >= (
    SELECT COALESCE(MAX(_loaded_at), '1900-01-01'::TIMESTAMP)
    FROM {{ this }}
  )
{% endif %}
```

### 2. Document Your Model

```yaml
# models/staging/schema.yml
models:
  - name: stg_products
    description: "Staging model for products"
    columns:
      - name: product_id
        description: "Unique product identifier"
        tests:
          - unique
          - not_null
```

### 3. Run Your New Model

```bash
dbt run --select stg_products
dbt test --select stg_products
```

## Troubleshooting

### Connection Issues

```bash
# Test connection details
dbt debug --profiles-dir ~/.dbt

# Check profile file syntax
cat ~/.dbt/profiles.yml
```

**Common Issues:**
- Account ID format: Use `xy12345.us-east-1`, not `xy12345`
- Role doesn't have permissions: Create schema, warehouse permissions needed
- Warehouse suspended: Wake it up in Snowflake UI

### Model Failures

```bash
# Check compiled SQL
cat target/compiled/dbt_snowflake_starter/models/staging/stg_orders.sql

# Run with debug output
dbt run --select stg_orders --debug

# Check Snowflake query history in UI
```

### Test Failures

```bash
# Run specific test with debug
dbt test --select stg_orders --debug

# Store failed records for inspection
dbt test --store-failures

# Check stored failures
SELECT * FROM db.schema.dbt_test__audit;
```

## Setting Up CI/CD with GitHub Actions

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Initial dbt setup"
   git push origin main
   ```

2. **Add Secrets to GitHub Repository**
   - Go to Settings → Secrets and variables → Actions
   - Add these secrets:
     - `SNOWFLAKE_ACCOUNT`
     - `SNOWFLAKE_USER`
     - `SNOWFLAKE_PASSWORD`
     - `SNOWFLAKE_DEV_DATABASE`
     - `SNOWFLAKE_STAGING_DATABASE`
     - `SNOWFLAKE_WAREHOUSE`
     - `SNOWFLAKE_DEV_ROLE`
     - `SNOWFLAKE_STAGING_ROLE`

3. **Create a Pull Request**
   - CI/CD workflow will run automatically
   - Check results in the Actions tab
   - See results commented on PR

## Best Practices to Follow

1. **Always run tests before pushing**
   ```bash
   dbt run && dbt test
   ```

2. **Review generated SQL**
   ```bash
   cat target/compiled/dbt_snowflake_starter/models/...
   ```

3. **Add tests for critical columns**
   - Every dimension key should have unique + not_null
   - Foreign keys should have relationships test
   - Amounts should have expression validation

4. **Document as you go**
   - Add column descriptions in schema.yml
   - Include model purpose comments
   - Document custom tests

5. **Use source freshness**
   - Define freshness expectations in schema.yml
   - Run `dbt source freshness` regularly
   - Alert on stale data

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Snowflake Setup](https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [Analytics Engineering Best Practices](https://www.getdbt.com/analytics-engineering/)
- [dbt Community Slack](https://community.getdbt.com/)

## Getting Help

1. **Check the README.md** for comprehensive documentation
2. **Review REPOSITORY_STRUCTURE.md** for detailed file descriptions
3. **Look at example models** (stg_orders.sql, dim_customers.sql, fct_orders.sql)
4. **Check dbt logs** in the logs/ directory
5. **Search dbt documentation** or community forums
6. **Contact Ram Marapally** on GitHub: [@rammarapally](https://github.com/rammarapally)

## Quick Reference

```bash
# Installation
pip install -r requirements.txt

# Connection
dbt debug

# Development
dbt run
dbt test
dbt docs generate
dbt docs serve

# Specific models
dbt run --select stg_orders
dbt test --select dim_customers

# Maintenance
dbt clean
dbt parse
dbt deps

# CI/CD
dbt run --target prod
dbt test --target staging
```

## Next Session Tips

To pick up where you left off:

```bash
# Activate virtual environment
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows

# View recent runs
dbt parse  # Validates project

# Continue development
dbt run --select models/...
dbt test --select models/...
```

---

**Happy modeling! 🚀**

For questions or issues, reach out to Ram Marapally on GitHub.
