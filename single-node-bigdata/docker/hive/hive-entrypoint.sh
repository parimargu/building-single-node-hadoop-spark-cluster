#!/bin/bash
# Hive Entrypoint Script
# Generates configuration files and starts Hive Metastore or HiveServer2

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
    log_info "Shutting down Hive $SERVICE_ROLE gracefully..."
    if [ -n "$SERVICE_PID" ]; then
        kill -TERM "$SERVICE_PID" 2>/dev/null || true
        wait "$SERVICE_PID" 2>/dev/null || true
    fi
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

# Generate Hive configuration files
generate_configs() {
    log_info "Generating Hive configuration files..."
    
    local NAMENODE_HOST=${NAMENODE_HOST:-namenode}
    local NAMENODE_IPC_PORT=${NAMENODE_IPC_PORT:-9000}
    local MYSQL_HOST=${MYSQL_HOST:-mysql}
    local MYSQL_PORT=${MYSQL_PORT:-3306}
    local MYSQL_DATABASE=${MYSQL_DATABASE:-hive_metastore}
    local MYSQL_USER=${MYSQL_USER:-hive}
    local MYSQL_PASSWORD=${MYSQL_PASSWORD:-hivepass}
    local HIVE_METASTORE_HOST=${HIVE_METASTORE_HOST:-hive-metastore}
    local HIVE_METASTORE_PORT=${HIVE_METASTORE_PORT:-9083}
    local HIVESERVER2_PORT=${HIVESERVER2_PORT:-10000}
    local HIVESERVER2_UI_PORT=${HIVESERVER2_UI_PORT:-10002}
    local HIVE_EXECUTION_ENGINE=${HIVE_EXECUTION_ENGINE:-mr}
    
    # Generate hive-site.xml
    cat > ${HIVE_HOME}/conf/hive-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}?createDatabaseIfNotExist=true&amp;useSSL=false&amp;allowPublicKeyRetrieval=true</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.cj.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>${MYSQL_USER}</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>${MYSQL_PASSWORD}</value>
    </property>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://${HIVE_METASTORE_HOST}:${HIVE_METASTORE_PORT}</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.server2.thrift.port</name>
        <value>${HIVESERVER2_PORT}</value>
    </property>
    <property>
        <name>hive.server2.webui.port</name>
        <value>${HIVESERVER2_UI_PORT}</value>
    </property>
    <property>
        <name>hive.server2.enable.doAs</name>
        <value>false</value>
    </property>
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>false</value>
    </property>
    <property>
        <name>datanucleus.schema.autoCreateAll</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.server2.authentication</name>
        <value>NONE</value>
    </property>
    <property>
        <name>hive.metastore.event.db.notification.api.auth</name>
        <value>false</value>
    </property>
    <property>
        <name>hive.execution.engine</name>
        <value>${HIVE_EXECUTION_ENGINE}</value>
    </property>
    <property>
        <name>spark.master</name>
        <value>spark://spark-master:7077</value>
    </property>
    <property>
        <name>spark.serializer</name>
        <value>org.apache.spark.serializer.KryoSerializer</value>
    </property>
</configuration>
EOF

    # Generate Hadoop core-site.xml for HDFS access
    mkdir -p ${HADOOP_CONF_DIR}
    cat > ${HADOOP_CONF_DIR}/core-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}</value>
    </property>
    <property>
        <name>hadoop.proxyuser.hive.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.hive.groups</name>
        <value>*</value>
    </property>
</configuration>
EOF

    log_info "Hive configuration files generated"
}

# Initialize Hive metastore schema
init_schema() {
    log_info "Initializing Hive metastore schema..."
    
    # Check if schema already exists
    if ${HIVE_HOME}/bin/schematool -dbType mysql -info 2>&1 | grep -q "Metastore schema version"; then
        log_info "Hive metastore schema already initialized"
    else
        log_info "Running schema initialization..."
        ${HIVE_HOME}/bin/schematool -dbType mysql -initSchema --verbose || {
            log_warn "Schema init failed, it might already exist. Continuing..."
        }
    fi
}

# Main execution
main() {
    local mode=${1:-$HIVE_MODE}
    
    if [ -z "$mode" ]; then
        log_error "No mode specified. Set HIVE_MODE environment variable or pass as argument."
        exit 1
    fi
    
    log_info "Starting Hive $mode..."
    
    # Generate configuration files
    generate_configs
    
    case "$mode" in
        metastore)
            # Wait for MySQL and HDFS
            wait_for_service ${MYSQL_HOST:-mysql} ${MYSQL_PORT:-3306} 180
            wait_for_service ${NAMENODE_HOST:-namenode} ${NAMENODE_IPC_PORT:-9000} 180
            
            # Initialize schema
            init_schema
            
            log_info "Starting Hive Metastore..."
            ${HIVE_HOME}/bin/hive --service metastore &
            SERVICE_PID=$!
            wait $SERVICE_PID
            ;;
        hiveserver2)
            # Wait for Metastore
            wait_for_service ${HIVE_METASTORE_HOST:-hive-metastore} ${HIVE_METASTORE_PORT:-9083} 180
            
            log_info "Starting HiveServer2..."
            ${HIVE_HOME}/bin/hive --service hiveserver2 &
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
