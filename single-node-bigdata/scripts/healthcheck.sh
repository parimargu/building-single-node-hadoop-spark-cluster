#!/bin/bash
# Health check script for Big Data cluster services
# Returns 0 if healthy, 1 if unhealthy

set -e

SERVICE_ROLE=${SERVICE_ROLE:-unknown}
MAX_RETRIES=${HEALTH_CHECK_RETRIES:-3}
RETRY_INTERVAL=${HEALTH_CHECK_INTERVAL:-5}

check_port() {
    local host=$1
    local port=$2
    nc -z "$host" "$port" 2>/dev/null
}

check_http() {
    local url=$1
    curl -sf "$url" > /dev/null 2>&1
}

check_with_retry() {
    local check_cmd=$1
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if eval "$check_cmd"; then
            return 0
        fi
        retries=$((retries + 1))
        if [ $retries -lt $MAX_RETRIES ]; then
            sleep $RETRY_INTERVAL
        fi
    done
    
    return 1
}

# Service-specific health checks
case "$SERVICE_ROLE" in
    namenode)
        check_with_retry "check_http http://localhost:9870/jmx"
        ;;
    datanode)
        check_with_retry "check_port localhost 9866"
        ;;
    resourcemanager)
        check_with_retry "check_http http://localhost:8088/ws/v1/cluster/info"
        ;;
    nodemanager)
        check_with_retry "check_port localhost 8042"
        ;;
    historyserver)
        check_with_retry "check_http http://localhost:19888/ws/v1/history/info"
        ;;
    spark-master)
        check_with_retry "check_http http://localhost:8080"
        ;;
    spark-worker)
        check_with_retry "check_http http://localhost:8081"
        ;;
    hive-metastore)
        check_with_retry "check_port localhost 9083"
        ;;
    hiveserver2)
        check_with_retry "check_port localhost 10000"
        ;;
    *)
        echo "Unknown service role: $SERVICE_ROLE"
        exit 1
        ;;
esac

exit $?
