#!/bin/bash
# Health check script for Hadoop services

set -e

SERVICE_ROLE=${SERVICE_ROLE:-unknown}
MAX_RETRIES=${HEALTH_CHECK_RETRIES:-3}
RETRY_INTERVAL=${HEALTH_CHECK_INTERVAL:-5}

check_port() {
    nc -z localhost "$1" 2>/dev/null
}

check_http() {
    curl -sf "$1" > /dev/null 2>&1
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

case "$SERVICE_ROLE" in
    namenode)
        check_with_retry "check_http http://localhost:9870/jmx"
        ;;
    datanode)
        check_with_retry "check_port 9866"
        ;;
    resourcemanager)
        check_with_retry "check_http http://localhost:8088/ws/v1/cluster/info"
        ;;
    nodemanager)
        check_with_retry "check_port 8042"
        ;;
    historyserver)
        check_with_retry "check_http http://localhost:19888/ws/v1/history/info"
        ;;
    *)
        echo "Unknown service role: $SERVICE_ROLE"
        exit 1
        ;;
esac

exit $?
