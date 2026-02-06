# Single-Node Apache Big Data Cluster

A fully containerized single-node Apache Big Data cluster using Docker and Docker Compose. This project includes Hadoop, Spark, Hive, and a modern monitoring dashboard.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Single-Node Big Data Cluster                   │
├──────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                         HADOOP                               │ │
│  │  NameNode │ DataNode │ ResourceManager │ NodeManager │ History│ │
│  └─────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────┐  ┌────────────────────────────────────┐ │
│  │       SPARK         │  │               HIVE                  │ │
│  │  Master │ Worker    │  │  Metastore (MySQL) │ HiveServer2   │ │
│  └─────────────────────┘  └────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                      MONITORING                              │ │
│  │        FastAPI Backend  │  ReactJS Dashboard                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Docker**: 20.10+ 
- **Docker Compose**: v2.0+
- **RAM**: Minimum 8 GB
- **Disk**: 20 GB free space

## Quick Start

### 1. Clone and Navigate

```bash
cd single-node-bigdata
```

### 2. Start the Cluster

```bash
docker compose up -d
```

This will:
- Build all Docker images
- Start all services in the correct order
- Initialize databases and create HDFS directories

### 3. Check Status

```bash
docker compose ps
```

### 4. Access Web UIs

| Service | URL | Description |
|---------|-----|-------------|
| **Monitoring Dashboard** | http://localhost:3000 | Cluster monitoring UI |
| **Monitoring API** | http://localhost:8000/docs | API documentation |
| **Hadoop NameNode** | http://localhost:9870 | HDFS overview |
| **YARN ResourceManager** | http://localhost:8088 | Job management |
| **Spark Master** | http://localhost:8080 | Spark cluster status |
| **Hive Web UI** | http://localhost:10002 | Hive web interface |
| **History Server** | http://localhost:19888 | Job history |

## Configuration

All configuration is driven by `cluster_config.yaml`. Key settings include:

```yaml
versions:
  java: 21
  hadoop: 3.4.2
  spark: 4.1.1
  hive: 4.2.0

ports:
  hadoop:
    namenode_ui: 9870
    resourcemanager_ui: 8088
  spark:
    master_ui: 8080
  hive:
    hiveserver2: 10000
```

## Container Access

Access containers directly:

```bash
# Hadoop NameNode
docker exec -it namenode bash

# Spark Master
docker exec -it spark-master bash

# Hive
docker exec -it hiveserver2 bash
```

## HDFS Commands

```bash
# Create directory
docker exec namenode hdfs dfs -mkdir /user/test

# List files
docker exec namenode hdfs dfs -ls /

# Upload file
docker exec namenode hdfs dfs -put /local/file /hdfs/path
```

## Hive Commands

```bash
# Connect via Beeline
docker exec -it hiveserver2 beeline -u "jdbc:hive2://localhost:10000"

# Run query
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -e "SHOW DATABASES;"
```

## Spark Commands

```bash
# Spark Shell
docker exec -it spark-master spark-shell

# PySpark
docker exec -it spark-master pyspark

# Submit job
docker exec spark-master spark-submit --master spark://spark-master:7077 your-app.jar
```

## Stop the Cluster

```bash
# Stop all services
docker compose down

# Stop and remove volumes (data will be lost)
docker compose down -v
```

## Monitoring Features

The monitoring dashboard provides:

- **Service Status**: Real-time status of all cluster services
- **Start/Stop Controls**: Start or stop individual services
- **Live Logs**: View container logs with auto-refresh
- **Web UI Links**: Quick access to service web interfaces
- **Dark Mode**: Toggle between light and dark themes

## Data Analysis Workflow

This project includes a sample data analysis workflow using PySpark.

### 1. Generate Sample Data

Generates 100 rows each for `customers.csv`, `products.csv`, and `orders.csv`.

```bash
docker exec -it spark-master python3 /scripts/generate_sample_data.py
```

### 2. Upload to HDFS

```bash
# Create directories
docker exec namenode hdfs dfs -mkdir -p /data
docker exec namenode hdfs dfs -mkdir -p /output

# Upload files
docker exec namenode hdfs dfs -put -f /tmp/sample_data/*.csv /data/
```

### 3. Run Analysis

The analysis script `analyze_data.py` performs joins and aggregations, saving results back to HDFS.

#### Spark Standalone Mode
```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  /scripts/analyze_data.py
```

#### YARN Mode
```bash
docker exec spark-master spark-submit \
  --master yarn \
  --deploy-mode client \
  /scripts/analyze_data.py
```

### 4. Verify Results

```bash
docker exec namenode hdfs dfs -ls -R /output/metrics
```

## Hive Data Analysis Workflow

A specialized workflow for Hive analysis including managed and external tables.

### 1. Prepare Data in HDFS

```bash
# Upload sample employees and departments
docker exec namenode hdfs dfs -mkdir -p /sample_data
docker exec namenode hdfs dfs -put /tmp/hive_sample_data/*.csv /sample_data/
```

### 2. Run Hive Analysis

The analysis uses a combination of Hive for table management and PySpark for robust analytical execution.

```bash
# Execute PySpark analysis
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  /scripts/analyze_hive_data_v2.py

# Register results in Hive
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -n hive -p hivepass -e "
CREATE EXTERNAL TABLE IF NOT EXISTS avg_salary_per_dept (dept_name STRING, avg_salary DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/hive_results/avg_salary_per_dept' TBLPROPERTIES ('skip.header.line.count'='1');
CREATE EXTERNAL TABLE IF NOT EXISTS highest_paid_per_dept (dept_name STRING, emp_name STRING, salary INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/hive_results/highest_paid_per_dept' TBLPROPERTIES ('skip.header.line.count'='1');
CREATE EXTERNAL TABLE IF NOT EXISTS employee_age_groups (age_group STRING, employee_count INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/hive_results/employee_age_groups' TBLPROPERTIES ('skip.header.line.count'='1');
CREATE EXTERNAL TABLE IF NOT EXISTS emp_count_per_dept (dept_name STRING, emp_count INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/hive_results/emp_count_per_dept' TBLPROPERTIES ('skip.header.line.count'='1');
CREATE EXTERNAL TABLE IF NOT EXISTS total_salary_per_dept (dept_name STRING, total_salary BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION '/hive_results/total_salary_per_dept' TBLPROPERTIES ('skip.header.line.count'='1');
"
```

### 3. Query Results in Hive

```bash
docker exec -it hiveserver2 beeline -u \"jdbc:hive2://localhost:10000\" -n hive -p hivepass -e \"SELECT * FROM avg_salary_per_dept;\"
```

## Resource Management (YARN)

The cluster is configured with dynamic YARN memory management. Settings in `cluster_config.yaml`:

- **NodeManager Memory**: 4096 MB
- **Min/Max Allocation**: 512 MB / 4096 MB
- **Virtual Memory Check**: Disabled (for container stability)

To update memory settings:
1. Edit `cluster_config.yaml`
2. Run `python3 scripts/generate-configs.py`
3. Restart YARN services: `docker compose up -d --build resourcemanager nodemanager`

## Hive Execution Engine (MapReduce, Tez, Spark)

This cluster supports switching between multiple execution strategies for Hive.

### Deep Analysis of Execution Engines in Hive 4.x

In Apache Hive 4.x, the native execution engines are **Tez** and **MapReduce (MR)**. The legacy "Hive on Spark" (using Spark as a Hive engine) has been deprecated in favor of using **Spark SQL** directly.

| Engine | Type | Best For... | Hive 4.x Support |
|--------|------|-------------|-------------------|
| **MapReduce (MR)** | Native | Reliability, Disk-intensive large batch jobs | ✅ Supported |
| **Tez** | Native | Default fast DAG-based analytics | ✅ Supported |
| **Spark SQL** | External | High-performance memory-intensive processing | ✅ Recommended (via Spark) |

**Analysis of the Move from Spark to Tez:**
Hive 4.x focuses on Tez for its native performance optimizations (LLAP, etc.). For Spark-based processing, the modern approach is to use the Spark ecosystem (Spark SQL/PySpark) to read/write to the same Hive Metastore, which this cluster is fully configured to do.

---

### How to Switch Native Engines (MR/Tez)

#### 1. Permanent Configuration (Centralized)
Edit `cluster_config.yaml`:
```yaml
services:
  hive:
    execution_engine: mr  # Options: mr, tez
```
Then regenerate configs and restart:
```bash
python3 scripts/generate-configs.py
docker compose up -d hive-metastore hiveserver2
```

#### 2. Session-level Switch (Runtime)
You can switch engines at runtime within a Beeline session:
```sql
-- Switch to MapReduce
SET hive.execution.engine=mr;

-- Switch to Tez
SET hive.execution.engine=tez;
```

### How to use Spark with Hive
Instead of setting Hive's engine to Spark, use the Spark cluster to execute Hive queries. This cluster includes Spark 4.x binaries in the Hive container for this purpose.

**Example using Spark-Shell:**
```bash
docker exec -it hiveserver2 spark-shell --master spark://spark-master:7077
spark.sql("SELECT COUNT(*) FROM employees").show()
```

#### Verification
To check the active native engine:
```bash
docker exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000" -n hive -p hivepass -e "SET hive.execution.engine;"
```

---

## Project Structure

```
single-node-bigdata/
├── cluster_config.yaml      # Central configuration
├── docker-compose.yml       # Docker Compose definition
├── docker/
│   ├── hadoop/              # Hadoop Dockerfile & scripts
│   ├── spark/               # Spark Dockerfile & scripts
│   ├── hive/                # Hive Dockerfile & scripts
│   ├── mysql/               # MySQL init scripts
│   └── postgres/            # PostgreSQL init scripts
├── monitoring/
│   ├── backend/             # FastAPI application
│   └── frontend/            # React dashboard
├── scripts/
│   ├── generate-configs.py  # Config generator
│   ├── entrypoint.sh        # Generic entrypoint
│   └── healthcheck.sh       # Health checks
└── README.md
```

## Troubleshooting

### Services not starting

Check logs:
```bash
docker compose logs <service-name>
```

### NameNode not formatting

Remove existing data and restart:
```bash
docker compose down -v
docker compose up -d
```

### Hive metastore connection issues

Ensure MySQL is healthy:
```bash
docker compose exec mysql mysqladmin ping -h localhost -u root -prootpass
```

## License

This project is provided as-is for educational and development purposes.
