# dbt-Snowflake-Starter - Complete File Index

**Author:** Ram Marapally (GitHub: [@rammarapally](https://github.com/rammarapally))
**Created:** January 31, 2025
**Version:** 1.0.0

Quick reference guide to all files in this repository.

## Documentation Files

Start here for orientation and guidance.

| File | Purpose | Size | Read Time |
|------|---------|------|-----------|
| [README.md](README.md) | Comprehensive guide with features, setup, and best practices | 9.3 KB | 15 min |
| [GETTING_STARTED.md](GETTING_STARTED.md) | Step-by-step setup guide with troubleshooting | 12 KB | 20 min |
| [REPOSITORY_STRUCTURE.md](REPOSITORY_STRUCTURE.md) | Detailed file descriptions and architecture | 13 KB | 15 min |
| [FILES_CREATED.md](FILES_CREATED.md) | Inventory of all created files and features | 8 KB | 10 min |
| [INDEX.md](INDEX.md) | This file - quick reference guide | 2 KB | 5 min |

## Configuration Files

Setup and project configuration.

| File | Purpose | Key Content |
|------|---------|-------------|
| [dbt_project.yml](dbt_project.yml) | Main dbt configuration | Project metadata, model settings, test configs |
| [profiles.yml.example](profiles.yml.example) | Snowflake connection template | Dev/staging/prod configs, auth methods |
| [requirements.txt](requirements.txt) | Python dependencies | dbt packages, development tools |
| [.gitignore](.gitignore) | Git ignore rules | Credentials, artifacts, IDE files |

## Model Files - Staging Layer

Raw data transformation and cleansing.

| File | Grain | Materialization | Tests | Metrics |
|------|-------|-----------------|-------|---------|
| [models/staging/stg_orders.sql](models/staging/stg_orders.sql) | One per order | Incremental (MERGE) | Unique, not null | 8 columns |
| [models/staging/schema.yml](models/staging/schema.yml) | - | Documentation | 40+ tests defined | Source specs |

### stg_orders.sql Details
- **Purpose:** Clean and standardize order data with incremental loading
- **Techniques:** ROW_NUMBER() deduplication, safe type casting, clustering
- **Key Columns:** order_id, customer_id, total_amount, order_status
- **Transformations:** Order size categorization, monetary type casting
- **Incremental Logic:** Loads only new/modified records since last run

### schema.yml Details
- **Source Definitions:** raw.orders, raw.customers with freshness checks
- **Model Documentation:** Complete column-level documentation
- **Test Specifications:** Uniqueness, not null, relationships, accepted values
- **Meta Information:** PII flags, metric/dimension classification

## Model Files - Marts Layer

Analytics-ready business tables.

| File | Grain | Materialization | Type | Key Metrics |
|------|-------|-----------------|------|-------------|
| [models/marts/dim_customers.sql](models/marts/dim_customers.sql) | One per customer | Table (full refresh) | Dimension | 15+ metrics |
| [models/marts/fct_orders.sql](models/marts/fct_orders.sql) | One per order | Incremental (MERGE) | Fact | 20+ metrics |

### dim_customers.sql Details
- **Purpose:** Customer dimension with lifecycle metrics and segmentation
- **Enrichments:** RFM analysis, customer lifetime value, lifecycle stage
- **Segments:** Customer value tier, recency segment classification
- **Metrics:** Orders count, spend, tenure, days since purchase
- **CTEs:** customer_staging, customer_orders, customer_recency, enriched

### fct_orders.sql Details
- **Purpose:** Orders fact table with detailed business metrics
- **Metrics:** Tax rate %, shipping rate %, markup %
- **Flags:** Fulfillment, cancellation, return status indicators
- **Dimensions:** Year, quarter, month, week, day attributes
- **Calculations:** Delivery lead time, order value categories

## Macro Files

Custom functions and utilities.

| File | Macros | Purpose |
|------|--------|---------|
| [macros/generate_schema_name.sql](macros/generate_schema_name.sql) | 6 functions | Schema naming, query tracking, type utilities |

### Included Macros

1. **generate_schema_name()** - Environment-based schema naming (dev/staging/prod)
2. **set_query_tag()** - Tag queries for cost tracking in Snowflake
3. **unset_query_tag()** - Clear query tags after execution
4. **get_incremental_days()** - Configurable lookback period for incremental loads
5. **create_monthly_snapshot()** - Convert dates to YYYYMM format
6. **cast_numeric_safe()** - Safe numeric type casting with null handling
7. **get_date_spine()** - Generate date dimension using Snowflake GENERATOR

## Test Files

Custom data quality validations.

| File | Tests | Purpose |
|------|-------|---------|
| [tests/generic/test_not_null_where.sql](tests/generic/test_not_null_where.sql) | 5 tests | Conditional and advanced validations |

### Included Tests

1. **test_not_null_where()** - Conditional null validation with WHERE clause
2. **test_expression_is_true()** - Validate SQL expressions on all rows
3. **test_consecutive_not_null()** - Check data continuity in time series
4. **test_relationships_where()** - Conditional foreign key validation
5. **test_uniqueness_with_conditions()** - Uniqueness validation with conditions

## CI/CD Configuration

Automated testing and deployment.

| File | Jobs | Triggers | Environments |
|------|------|----------|--------------|
| [.github/workflows/dbt_ci.yml](.github/workflows/dbt_ci.yml) | 6 jobs | Push, PR | Dev, staging |

### CI/CD Jobs

1. **dbt_parse** - Validates project structure
2. **dbt_run** - Executes models in dev and staging
3. **dbt_test** - Runs data quality tests
4. **dbt_docs** - Generates documentation
5. **code_quality** - Checks formatting and linting
6. **comment_pr** - Posts results to pull requests

## How to Use This Repository

### New Users
1. Start with [GETTING_STARTED.md](GETTING_STARTED.md) - step-by-step setup
2. Read [README.md](README.md) - understand features and architecture
3. Review example models - see patterns in action

### Experienced dbt Users
1. Check [dbt_project.yml](dbt_project.yml) - configuration approach
2. Review [models/staging/schema.yml](models/staging/schema.yml) - documentation patterns
3. Examine macros and tests - extend with your own

### Model Development
1. Reference [models/staging/stg_orders.sql](models/staging/stg_orders.sql) - staging template
2. Reference [models/marts/dim_customers.sql](models/marts/dim_customers.sql) - dimension template
3. Reference [models/marts/fct_orders.sql](models/marts/fct_orders.sql) - fact template

### Testing & Quality
1. Study [models/staging/schema.yml](models/staging/schema.yml) - test definitions
2. Review [tests/generic/test_not_null_where.sql](tests/generic/test_not_null_where.sql) - custom tests
3. Use examples as templates for new tests

### CI/CD Setup
1. Review [.github/workflows/dbt_ci.yml](.github/workflows/dbt_ci.yml) - workflow structure
2. Follow steps in [GETTING_STARTED.md](GETTING_STARTED.md#setting-up-cicd-with-github-actions)
3. Configure required secrets in GitHub

## Quick Reference Commands

```bash
# Setup
pip install -r requirements.txt
cp profiles.yml.example ~/.dbt/profiles.yml
dbt debug

# Development
dbt run
dbt test
dbt docs generate && dbt docs serve

# Specific Models
dbt run --select stg_orders
dbt test --select dim_customers

# Advanced
dbt run --full-refresh
dbt snapshot
dbt seed
dbt clean
```

## File Statistics

| Category | Count | Lines | Size |
|----------|-------|-------|------|
| Documentation | 5 | 1,540+ | 45 KB |
| Configuration | 4 | 303 | 19 KB |
| Models (SQL) | 2 | 295+ | 10 KB |
| Schema YAML | 1 | 400+ | 15 KB |
| Macros | 1 | 200+ | 8 KB |
| Tests | 1 | 300+ | 10 KB |
| CI/CD Workflow | 1 | 200+ | 8 KB |
| Git Config | 1 | 140+ | 5.7 KB |
| Total | 16+ | 3,400+ | 120+ KB |

## Key Features at a Glance

### Snowflake Optimized
- Clustering keys for performance
- Incremental materializations
- Dynamic schema naming
- Query tags for cost tracking

### Best Practices
- Three-layer architecture
- Comprehensive naming conventions
- YAML documentation
- Incremental models
- SCD Type 2 patterns

### Data Quality
- 40+ tests defined
- Freshness checks
- Referential integrity
- Custom validations
- Test failure storage

### Production Ready
- Error handling
- Security best practices
- Complete documentation
- CI/CD pipeline
- Multiple environments

## Navigation Guide

**For Setup:** [GETTING_STARTED.md](GETTING_STARTED.md)

**For Understanding:** [README.md](README.md)

**For Details:** [REPOSITORY_STRUCTURE.md](REPOSITORY_STRUCTURE.md)

**For Reference:** [dbt_project.yml](dbt_project.yml), [models/staging/schema.yml](models/staging/schema.yml)

**For Examples:** [models/staging/stg_orders.sql](models/staging/stg_orders.sql), [models/marts/dim_customers.sql](models/marts/dim_customers.sql)

## Support & Questions

- GitHub Issues: File issues on the repository
- Documentation: See [README.md](README.md) troubleshooting section
- Examples: Study the included models and tests
- Best Practices: Review [REPOSITORY_STRUCTURE.md](REPOSITORY_STRUCTURE.md)

## Author

**Ram Marapally**
- GitHub: [@rammarapally](https://github.com/rammarapally)
- Analytics Engineering and Data Transformation

---

**Repository Version:** 1.0.0
**Created:** January 31, 2025
**Last Updated:** January 31, 2025
**dbt Version:** 1.5+
**Snowflake Version:** All current versions
