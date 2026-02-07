#!/bin/bash
# Jupyter Entrypoint Script
# Generates configuration files for Hadoop, Spark, and Hive, then starts Jupyter Lab

set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Generate configuration files from environment variables
generate_configs() {
    log_info "Generating configuration files for Jupyter service..."
    
    local NAMENODE_HOST=${NAMENODE_HOST:-namenode}
    local NAMENODE_IPC_PORT=${NAMENODE_IPC_PORT:-9000}
    local RM_HOST=${RM_HOST:-resourcemanager}
    local RM_ADDRESS_PORT=${RM_ADDRESS_PORT:-8032}
    local SPARK_MASTER_HOST=${SPARK_MASTER_HOST:-spark-master}
    local SPARK_MASTER_PORT=${SPARK_MASTER_PORT:-7077}
    local HIVE_METASTORE_HOST=${HIVE_METASTORE_HOST:-hive-metastore}
    local HIVE_METASTORE_PORT=${HIVE_METASTORE_PORT:-9083}
    
    # Generate Hadoop core-site.xml
    mkdir -p ${HADOOP_CONF_DIR}
    cat > ${HADOOP_CONF_DIR}/core-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}</value>
    </property>
</configuration>
EOF

    # Generate Hadoop yarn-site.xml
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
</configuration>
EOF

    # Generate Spark spark-defaults.conf
    mkdir -p ${SPARK_HOME}/conf
    cat > ${SPARK_HOME}/conf/spark-defaults.conf << EOF
spark.master                     spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/spark-logs
spark.sql.warehouse.dir          hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/user/hive/warehouse
spark.hadoop.hive.metastore.uris thrift://${HIVE_METASTORE_HOST}:${HIVE_METASTORE_PORT}
spark.sql.catalogImplementation  hive
spark.history.fs.logDirectory    hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/spark-logs
EOF

    # Generate Hive hive-site.xml
    mkdir -p ${HIVE_HOME}/conf
    cat > ${HIVE_HOME}/conf/hive-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://${HIVE_METASTORE_HOST}:${HIVE_METASTORE_PORT}</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>hdfs://${NAMENODE_HOST}:${NAMENODE_IPC_PORT}/user/hive/warehouse</value>
    </property>
</configuration>
EOF

    log_info "Configuration files generated successfully"
}

# Main execution
main() {
    log_info "Starting Jupyter Lab service..."
    
    # Generate configuration files
    generate_configs
    
    # Start Jupyter Lab
    # Note: PYSPARK_DRIVER_PYTHON and PYSPARK_DRIVER_PYTHON_OPTS are set in Dockerfile
    # to trigger jupyter lab when running 'pyspark'
    
    log_info "Jupyter Lab is starting on port 8888"
    exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
}

main "$@"
