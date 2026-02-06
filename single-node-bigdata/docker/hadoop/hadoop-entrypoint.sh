#!/bin/bash
# Hadoop Entrypoint Script
# Generates configuration files and starts the appropriate Hadoop service

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
    log_info "Shutting down Hadoop $SERVICE_ROLE gracefully..."
    case "$SERVICE_ROLE" in
        namenode)
            hdfs --daemon stop namenode 2>/dev/null || true
            ;;
        datanode)
            hdfs --daemon stop datanode 2>/dev/null || true
            ;;
        resourcemanager)
            yarn --daemon stop resourcemanager 2>/dev/null || true
            ;;
        nodemanager)
            yarn --daemon stop nodemanager 2>/dev/null || true
            ;;
        historyserver)
            mapred --daemon stop historyserver 2>/dev/null || true
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

# Generate Hadoop configuration files from environment variables
generate_configs() {
    log_info "Generating Hadoop configuration files..."
    
    local NAMENODE_HOST=${NAMENODE_HOST:-namenode}
    local NAMENODE_IPC_PORT=${NAMENODE_IPC_PORT:-9000}
    local NAMENODE_UI_PORT=${NAMENODE_UI_PORT:-9870}
    local RM_HOST=${RM_HOST:-resourcemanager}
    local RM_UI_PORT=${RM_UI_PORT:-8088}
    local HS_HOST=${HS_HOST:-historyserver}
    local HS_UI_PORT=${HS_UI_PORT:-19888}
    local HS_ADDRESS_PORT=${HS_ADDRESS_PORT:-10020}
    
    # Generate core-site.xml
    cat > ${HADOOP_CONF_DIR}/core-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop/tmp</value>
    </property>
    <property>
        <name>hadoop.proxyuser.hive.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.hive.groups</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.http.filter.initializers</name>
        <value>org.apache.hadoop.security.HttpCrossOriginFilterInitializer</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.allowed-origins</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.allowed-methods</name>
        <value>GET,POST,OPTIONS,HEAD</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.allowed-headers</name>
        <value>X-Requested-With,Content-Type,Accept,Origin</value>
    </property>
</configuration>
EOF

    local DATANODE_HTTP_PORT=${DATANODE_HTTP_PORT:-9864}

    # Generate hdfs-site.xml
    cat > ${HADOOP_CONF_DIR}/hdfs-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/data/datanode</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>${NAMENODE_HOST}:${NAMENODE_UI_PORT}</value>
    </property>
    <property>
        <name>dfs.datanode.http.address</name>
        <value>0.0.0.0:${DATANODE_HTTP_PORT}</value>
    </property>
    <property>
        <name>dfs.datanode.use.datanode.hostname</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.client.use.datanode.hostname</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
</configuration>
EOF

    local YARN_NM_MEMORY_MB=${YARN_NM_MEMORY_MB:-4096}
    local YARN_NM_CPU_VCORES=${YARN_NM_CPU_VCORES:-4}
    local YARN_SCHED_MIN_ALLOC_MB=${YARN_SCHED_MIN_ALLOC_MB:-512}
    local YARN_SCHED_MAX_ALLOC_MB=${YARN_SCHED_MAX_ALLOC_MB:-4096}

    # Generate yarn-site.xml
    cat > ${HADOOP_CONF_DIR}/yarn-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>${RM_HOST}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>${RM_HOST}:${RM_UI_PORT}</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>${YARN_NM_MEMORY_MB}</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>${YARN_NM_CPU_VCORES}</value>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>${YARN_SCHED_MIN_ALLOC_MB}</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>${YARN_SCHED_MAX_ALLOC_MB}</value>
    </property>
    <property>
        <name>yarn.nodemanager.local-dirs</name>
        <value>/opt/hadoop/data/nodemanager/local</value>
    </property>
    <property>
        <name>yarn.nodemanager.log-dirs</name>
        <value>/opt/hadoop/data/nodemanager/logs</value>
    </property>
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.nodemanager.remote-app-log-dir</name>
        <value>/app-logs</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.nodemanager.pmem-check-enabled</name>
        <value>false</value>
    </property>
</configuration>
EOF

    # Generate mapred-site.xml
    cat > ${HADOOP_CONF_DIR}/mapred-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>${HS_HOST}:${HS_ADDRESS_PORT}</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>${HS_HOST}:${HS_UI_PORT}</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop</value>
    </property>
</configuration>
EOF

    log_info "Configuration files generated successfully"
}

# Format NameNode if not already formatted
format_namenode() {
    local NAMENODE_DIR="/opt/hadoop/data/namenode"
    
    if [ ! -d "$NAMENODE_DIR/current" ]; then
        log_info "Formatting NameNode..."
        hdfs namenode -format -force -nonInteractive
        log_info "NameNode formatted successfully"
    else
        log_info "NameNode already formatted, skipping..."
    fi
}

# Create HDFS directories
create_hdfs_directories() {
    log_info "Creating HDFS directories..."
    
    # Wait for HDFS to be ready
    sleep 10
    
    hdfs dfs -mkdir -p /user/hive/warehouse || true
    hdfs dfs -mkdir -p /spark-logs || true
    hdfs dfs -mkdir -p /app-logs || true
    hdfs dfs -chmod -R 777 /user/hive/warehouse || true
    hdfs dfs -chmod -R 777 /spark-logs || true
    hdfs dfs -chmod -R 777 /app-logs || true
    
    log_info "HDFS directories created"
}

# Main execution
main() {
    local role=${1:-$SERVICE_ROLE}
    
    if [ -z "$role" ]; then
        log_error "No role specified. Set SERVICE_ROLE environment variable or pass as argument."
        exit 1
    fi
    
    log_info "Starting Hadoop service: $role"
    
    # Generate configuration files
    generate_configs
    
    case "$role" in
        namenode)
            format_namenode
            log_info "Starting NameNode..."
            hdfs namenode &
            SERVICE_PID=$!
            
            # Create HDFS directories in background after NameNode starts
            (sleep 30 && create_hdfs_directories) &
            
            wait $SERVICE_PID
            ;;
        datanode)
            wait_for_service namenode ${NAMENODE_IPC_PORT:-9000}
            log_info "Starting DataNode..."
            hdfs datanode &
            SERVICE_PID=$!
            wait $SERVICE_PID
            ;;
        resourcemanager)
            wait_for_service namenode ${NAMENODE_IPC_PORT:-9000}
            log_info "Starting ResourceManager..."
            yarn resourcemanager &
            SERVICE_PID=$!
            wait $SERVICE_PID
            ;;
        nodemanager)
            wait_for_service resourcemanager ${RM_ADDRESS_PORT:-8032}
            log_info "Starting NodeManager..."
            yarn nodemanager &
            SERVICE_PID=$!
            wait $SERVICE_PID
            ;;
        historyserver)
            wait_for_service namenode ${NAMENODE_IPC_PORT:-9000}
            log_info "Starting HistoryServer..."
            mapred historyserver &
            SERVICE_PID=$!
            wait $SERVICE_PID
            ;;
        *)
            log_error "Unknown role: $role"
            exit 1
            ;;
    esac
}

main "$@"
