#!/bin/bash
# Spark Entrypoint Script
# Generates configuration files and starts Spark Master or Worker

set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Graceful shutdown handler
shutdown_handler() {
    log_info "Shutting down Spark $SERVICE_ROLE gracefully..."
    case "$SPARK_MODE" in
        master)
            ${SPARK_HOME}/sbin/stop-master.sh 2>/dev/null || true
            ;;
        worker)
            ${SPARK_HOME}/sbin/stop-worker.sh 2>/dev/null || true
            ;;
    esac
    exit 0
}

trap shutdown_handler SIGTERM SIGINT SIGQUIT

# Wait for a service to be available
wait_for_service() {
    local host=$1
    local port=$2
    local timeout=${3:-120}
    local elapsed=0
    
    log_info "Waiting for $host:$port..."
    while ! nc -z "$host" "$port" 2>/dev/null; do
        if [ $elapsed -ge $timeout ]; then
            log_error "Timeout waiting for $host:$port"
            return 1
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    log_info "$host:$port is available"
}

# Generate Spark configuration files
generate_configs() {
    log_info "Generating Spark configuration files..."
    
    local NAMENODE_HOST=${NAMENODE_HOST:-namenode}
    local NAMENODE_IPC_PORT=${NAMENODE_IPC_PORT:-9000}
    local SPARK_MASTER_HOST=${SPARK_MASTER_HOST:-spark-master}
    local SPARK_MASTER_PORT=${SPARK_MASTER_PORT:-7077}
    local HIVE_METASTORE_HOST=${HIVE_METASTORE_HOST:-hive-metastore}
    local HIVE_METASTORE_PORT=${HIVE_METASTORE_PORT:-9083}
    local SPARK_DRIVER_MEMORY=${SPARK_DRIVER_MEMORY:-1g}
    local SPARK_EXECUTOR_MEMORY=${SPARK_EXECUTOR_MEMORY:-2g}
    local SPARK_EXECUTOR_CORES=${SPARK_EXECUTOR_CORES:-2}
    
    # Generate spark-defaults.conf
    cat > ${SPARK_HOME}/conf/spark-defaults.conf << EOF
# Spark Configuration - Generated at container startup

spark.master                     spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/spark-logs
spark.history.fs.logDirectory    hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/spark-logs
spark.sql.warehouse.dir          hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/user/hive/warehouse
spark.hadoop.hive.metastore.uris thrift://${HIVE_METASTORE_HOST}:${HIVE_METASTORE_PORT}
spark.sql.catalogImplementation  hive
spark.driver.memory              ${SPARK_DRIVER_MEMORY}
spark.executor.memory            ${SPARK_EXECUTOR_MEMORY}
spark.executor.cores             ${SPARK_EXECUTOR_CORES}
spark.ui.reverseProxy            true
EOF

    # Generate Hadoop configuration files for HDFS and YARN access
    mkdir -p ${HADOOP_CONF_DIR}
    
    # core-site.xml
    cat > ${HADOOP_CONF_DIR}/core-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}</value>
    </property>
</configuration>
EOF

    # hdfs-site.xml (needed for some HDFS client operations)
    cat > ${HADOOP_CONF_DIR}/hdfs-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

    # yarn-site.xml (REQUIRED for --master yarn)
    local RM_HOST=${RM_HOST:-resourcemanager}
    local RM_UI_PORT=${RM_UI_PORT:-8088}
    local RM_ADDRESS_PORT=${RM_ADDRESS_PORT:-8032}
    
    cat > ${HADOOP_CONF_DIR}/yarn-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>${RM_HOST}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>${RM_HOST}:${RM_ADDRESS_PORT}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>${RM_HOST}:${RM_UI_PORT}</value>
    </property>
</configuration>
EOF


    log_info "Spark configuration files generated"
}

# Main execution
main() {
    local mode=${1:-$SPARK_MODE}
    
    if [ -z "$mode" ]; then
        log_error "No mode specified. Set SPARK_MODE environment variable or pass as argument."
        exit 1
    fi
    
    log_info "Starting Spark $mode..."
    
    # Generate configuration files
    generate_configs
    
    case "$mode" in
        master)
            # Wait for HDFS to be available
            wait_for_service ${NAMENODE_HOST:-namenode} ${NAMENODE_IPC_PORT:-9000}
            
            log_info "Starting Spark Master..."
            ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.master.Master \
                --host 0.0.0.0 \
                --port ${SPARK_MASTER_PORT:-7077} \
                --webui-port ${SPARK_MASTER_UI_PORT:-8080} &
            SERVICE_PID=$!
            wait $SERVICE_PID
            ;;
        worker)
            # Wait for Spark Master to be available
            wait_for_service ${SPARK_MASTER_HOST:-spark-master} ${SPARK_MASTER_PORT:-7077}
            
            log_info "Starting Spark Worker..."
            ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.worker.Worker \
                spark://${SPARK_MASTER_HOST:-spark-master}:${SPARK_MASTER_PORT:-7077} \
                --webui-port ${SPARK_WORKER_UI_PORT:-8081} \
                --memory ${SPARK_WORKER_MEMORY:-2g} \
                --cores ${SPARK_WORKER_CORES:-2} &
            SERVICE_PID=$!
            wait $SERVICE_PID
            ;;
        *)
            log_error "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

main "$@"
