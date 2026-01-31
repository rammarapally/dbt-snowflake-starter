# dbt-Snowflake-Starter Repository Structure

**Author:** Ram Marapally (GitHub: rammarapally)
**Last Updated:** January 2025
**dbt Version:** 1.5+
**Snowflake Support:** All current versions

## Complete Directory Structure

```
dbt-snowflake-starter/
├── .github/
│   └── workflows/
│       └── dbt_ci.yml                    # GitHub Actions CI/CD pipeline
│
├── models/
│   ├── staging/                          # Layer 1: Raw data transformations
│   │   ├── stg_orders.sql                # Staging model with incremental load
│   │   └── schema.yml                    # Schema definitions and tests
│   ├── marts/                            # Layer 2: Analytics-ready tables
│   │   ├── dim_customers.sql             # Customer dimension
│   │   └── fct_orders.sql                # Orders fact table
│   └── intermediate/                     # Optional: Intermediate layer (empty)
│
├── macros/
│   └── generate_schema_name.sql          # Custom macros for dbt
│                                         # - Schema naming strategy
│                                         # - Query tagging utilities
│                                         # - Snowflake-specific functions
│
├── tests/
│   └── generic/
│       └── test_not_null_where.sql       # Custom generic tests
│                                         # - Conditional null checks
│                                         # - Expression validation
│                                         # - Relationship validation
│
├── snapshots/                            # SCD Type 2 tracking (optional)
├── analysis/                             # Ad-hoc analysis queries
├── data/                                 # CSV seed files
│
├── dbt_project.yml                       # Main dbt configuration
├── profiles.yml.example                  # Snowflake connection template
├── requirements.txt                      # Python dependencies
├── .gitignore                            # Git ignore rules
├── README.md                             # Comprehensive documentation
└── REPOSITORY_STRUCTURE.md               # This file

```

## File Descriptions

### Configuration Files

#### `dbt_project.yml`
- Project metadata and version configuration
- Model materialization settings (incremental, table, view)
- Global configuration for staging and marts layers
- Test configuration with store_failures enabled
- Dispatch configuration for dbt-utils
- Quoting strategy for Snowflake identifiers
- Variable definitions for dynamic logic

**Key Sections:**
- `models`: Layer-specific configurations
- `tests`: Test settings and schemas
- `seeds`: Seed data configuration
- `snapshots`: SCD Type 2 settings

#### `profiles.yml.example`
- Template for Snowflake authentication
- Configurations for dev/staging/prod environments
- Multiple authentication methods (password, key pair, SSO)
- Warehouse and role specifications
- Thread configurations for parallel execution
- Connection pooling and session settings
- Security notes and best practices

**Features:**
- Password-based authentication example
- Key pair authentication for CI/CD
- SSO (external browser) authentication
- Environment variable integration
- Comprehensive troubleshooting section

#### `requirements.txt`
- dbt-core and dbt-snowflake packages
- dbt utilities and expectations packages
- Data manipulation tools (pandas, numpy)
- Testing frameworks (pytest, pytest-cov)
- Code quality tools (black, flake8, isort)
- Type checking (mypy)
- Development tools (jupyter, ipython)

### Model Files

#### `models/staging/stg_orders.sql`
**Purpose:** Clean and transform raw order data

**Features:**
- Incremental materialization with MERGE strategy
- Automatic deduplication
- Data type casting to Snowflake standards
- Derived columns (order_size_category)
- Clustering optimization for performance
- Comprehensive audit and metadata columns

**Grain:** One record per order
**Materialization:** Incremental (merge)
**Update Frequency:** Daily

**Key Columns:**
- `order_id`: Primary key
- `customer_id`: Foreign key
- `order_status`: Standardized status field
- `total_amount`: Monetary value (NUMERIC)
- `order_size_category`: Derived classification

#### `models/staging/schema.yml`
**Purpose:** Define sources, models, columns, tests, and documentation

**Sections:**
1. **Sources**: Raw data tables with freshness checks
   - `raw.orders`: Order transaction data
   - `raw.customers`: Customer master data

2. **Models**: Staged transformation models
   - `stg_orders`: Detailed order staging
   - `stg_customers`: Detailed customer staging

3. **Tests**: Data quality validations
   - Uniqueness tests
   - Not null constraints
   - Relationships/foreign keys
   - Accepted values
   - Custom expression-based tests

**Meta Attributes:**
- Ownership and SLA information
- PII (personally identifiable information) flags
- Metric vs dimension classification
- SQL data types
- Derived indicator flags

#### `models/marts/dim_customers.sql`
**Purpose:** Customer dimension table for analytics

**Features:**
- Full refresh materialization
- Comprehensive customer metrics aggregation
- Lifecycle stage calculation
- Customer value segmentation (RFM-inspired)
- Recency and tenure metrics
- Customer value tiering

**Grain:** One record per unique customer (current state)
**Materialization:** Table (full refresh)

**Key Dimensions:**
- Customer demographics (name, email, segment)
- Lifecycle stage (new, loyal, churned, etc.)
- Value tiers (premium, high-value, standard, etc.)
- Recency segment (active, at_risk, inactive, dormant)

**Key Metrics:**
- `lifetime_value`: Total spending
- `total_orders`: Order count
- `avg_order_value`: Average order amount
- `customer_age_months`: Tenure calculation
- `days_since_last_purchase`: Recency

#### `models/marts/fct_orders.sql`
**Purpose:** Orders fact table with business metrics

**Features:**
- Incremental materialization for performance
- Dimensional keys for star schema design
- Business indicator flags
- Derived metrics (tax rate %, shipping rate %)
- Order categorization (value, fulfillment status)
- Date dimension attributes

**Grain:** One record per order
**Materialization:** Incremental (merge)

**Key Metrics:**
- Amount fields: `order_amount`, `tax_amount`, `shipping_amount`, `total_amount`
- Flags: `is_fulfilled_flag`, `is_cancelled_flag`, `is_returned_flag`
- Percentages: `tax_rate_pct`, `shipping_rate_pct`, `markup_pct`
- Categories: `order_value_category`, `order_status`
- Lead time: `delivery_days`

**Date Dimensions:**
- Year, quarter, month, week, day of week attributes
- Separate delivery date dimensions

### Macro Files

#### `macros/generate_schema_name.sql`
**Purpose:** Custom schema naming strategy and utility functions

**Macros Included:**

1. **generate_schema_name()**
   - Implements environment-based schema naming
   - Creates separate schemas for dev/staging/prod
   - Schema suffix based on model layer (staging, marts, etc.)
   - Example: `dbt_dev_staging`, `dbt_prod_marts`

2. **set_query_tag()** / **unset_query_tag()**
   - Sets Snowflake query tags for cost tracking
   - Helps identify which model is running
   - Useful for billing allocation

3. **get_incremental_days()**
   - Returns lookback period for incremental loads
   - Configurable via dbt variables
   - Default: 7 days

4. **create_monthly_snapshot()**
   - Converts date to YYYYMM format
   - Useful for monthly aggregations

5. **cast_numeric_safe()**
   - Safe numeric casting with null handling
   - Defaults to 0.00 on failure
   - Configurable precision and scale

6. **get_date_spine()**
   - Generates date dimension spine
   - Uses Snowflake GENERATOR function
   - Efficient alternative to recursive CTEs

### Test Files

#### `tests/generic/test_not_null_where.sql`
**Purpose:** Custom generic tests for data quality

**Tests Included:**

1. **test_not_null_where()**
   - Conditional null check
   - Tests null values only for rows matching WHERE clause
   - Example: Check delivery_date not null only for DELIVERED orders

2. **test_expression_is_true()**
   - Validates SQL expressions
   - Example: Verify total_amount = order_amount + tax + shipping

3. **test_consecutive_not_null()**
   - Checks data continuity across time periods
   - Detects gaps in daily records

4. **test_relationships_where()**
   - Conditional referential integrity
   - Foreign key validation with WHERE filters
   - Example: Check customer_id exists only for active orders

5. **test_uniqueness_with_conditions()**
   - Conditional uniqueness validation
   - Example: Email must be unique for active customers only

### CI/CD Files

#### `.github/workflows/dbt_ci.yml`
**Purpose:** Automated testing and deployment pipeline

**Jobs:**
1. **dbt_parse**: Validates project structure
2. **dbt_run**: Executes models (dev and staging)
3. **dbt_test**: Runs data quality tests
4. **dbt_docs**: Generates documentation
5. **code_quality**: Checks code formatting
6. **comment_pr**: Posts results to pull requests

**Triggers:**
- Push to main/develop/feature branches
- Pull requests to main/develop
- Only runs on changes to dbt files

**Features:**
- Parallel execution for multiple environments
- Artifact uploads for inspection
- Pull request comments with results
- Automatic test report generation

**Required Secrets:**
- SNOWFLAKE_ACCOUNT
- SNOWFLAKE_USER
- SNOWFLAKE_PASSWORD
- SNOWFLAKE_*_DATABASE (dev, staging)
- SNOWFLAKE_WAREHOUSE
- SNOWFLAKE_*_ROLE (dev, staging)

### Documentation Files

#### `README.md`
Comprehensive guide including:
- Quick start instructions
- Feature overview
- Project structure explanation
- Model layer documentation
- Key features and optimizations
- Testing strategy
- Running dbt commands
- CI/CD integration
- Best practices
- Troubleshooting
- Resources and links

#### `.gitignore`
Comprehensive ignore rules for:
- dbt artifacts (target/, logs/, dbt_packages/)
- Python environments and cache
- IDE configuration (.vscode/, .idea/, etc.)
- OS-specific files (.DS_Store, Thumbs.db)
- Sensitive files (credentials, .env, profiles.yml)
- Build artifacts and distributions
- Test outputs and temporary files
- Documentation files (optional)

## How to Use This Repository

### 1. Initial Setup
```bash
# Clone repository
git clone https://github.com/rammarapally/dbt-snowflake-starter.git
cd dbt-snowflake-starter

# Install dependencies
pip install -r requirements.txt

# Configure Snowflake connection
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your credentials

# Verify connection
dbt debug
```

### 2. Running Models
```bash
# Run all models
dbt run

# Run specific layer
dbt run --select models/staging

# Run with specific target
dbt run --target prod

# Run with threads
dbt run --threads 8
```

### 3. Running Tests
```bash
# Run all tests
dbt test

# Run specific test
dbt test --select stg_orders

# Run only data quality tests
dbt test --select tag:data_quality

# Store test failures
dbt test --store-failures
```

### 4. Generating Documentation
```bash
# Generate manifest and catalog
dbt docs generate

# Serve documentation locally
dbt docs serve
```

### 5. Adding New Models
1. Create SQL file in appropriate directory
2. Document in schema.yml
3. Add tests for critical columns
4. Run `dbt run` and `dbt test`
5. Generate docs: `dbt docs generate`

## Key Features Summary

- **Incremental Loading**: Efficient processing of new/changed data
- **Snowflake Optimized**: Clustering keys, session parameters, dynamic SQL
- **Data Quality**: Comprehensive testing framework
- **Documentation**: YAML-based schema documentation
- **Custom Macros**: Utility functions for common tasks
- **CI/CD Ready**: GitHub Actions workflow included
- **Best Practices**: Naming conventions, code organization, performance
- **Scalable**: Ready for enterprise data warehouses

## Best Practices Implemented

1. **Naming Conventions**
   - Staging: `stg_<source>_<entity>`
   - Dimensions: `dim_<entity>`
   - Facts: `fct_<process>`

2. **Code Organization**
   - Models organized by layer
   - One model per file
   - Clear SQL formatting
   - Consistent indentation

3. **Testing Strategy**
   - Every model documented
   - Critical columns tested
   - Custom tests for business logic
   - Test coverage documented

4. **Performance**
   - Incremental models for large tables
   - Clustering keys on fact tables
   - Efficient SQL patterns
   - Materialization strategy per model

5. **Documentation**
   - Comprehensive YAML definitions
   - Column-level documentation
   - Test documentation
   - README in each directory

## Contact

For questions or contributions, contact Ram Marapally on GitHub: [@rammarapally](https://github.com/rammarapally)
