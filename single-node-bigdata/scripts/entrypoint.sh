#!/bin/bash
# Entrypoint script for Big Data cluster containers
# Generates configs at runtime and starts the appropriate service

set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Graceful shutdown handler
shutdown_handler() {
    log_info "Received shutdown signal, stopping service gracefully..."
    if [ -n "$SERVICE_PID" ]; then
        kill -TERM "$SERVICE_PID" 2>/dev/null || true
        wait "$SERVICE_PID" 2>/dev/null || true
    fi
    exit 0
}

trap shutdown_handler SIGTERM SIGINT SIGQUIT

# Validate environment
validate_environment() {
    log_info "Validating environment..."
    
    if [ -z "$SERVICE_ROLE" ]; then
        log_error "SERVICE_ROLE environment variable not set"
        exit 1
    fi
    
    log_info "Service role: $SERVICE_ROLE"
}

# Wait for a service to be available
wait_for_service() {
    local host=$1
    local port=$2
    local timeout=${3:-60}
    local elapsed=0
    
    log_info "Waiting for $host:$port to be available (timeout: ${timeout}s)..."
    
    while ! nc -z "$host" "$port" 2>/dev/null; do
        if [ $elapsed -ge $timeout ]; then
            log_error "Timeout waiting for $host:$port"
            return 1
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    log_info "$host:$port is available"
    return 0
}

# Main execution
main() {
    validate_environment
    
    log_info "Starting service: $SERVICE_ROLE"
    
    # Execute the specific entrypoint based on service type
    case "$SERVICE_TYPE" in
        hadoop)
            exec /entrypoints/hadoop-entrypoint.sh
            ;;
        spark)
            exec /entrypoints/spark-entrypoint.sh
            ;;
        hive)
            exec /entrypoints/hive-entrypoint.sh
            ;;
        *)
            log_error "Unknown service type: $SERVICE_TYPE"
            exit 1
            ;;
    esac
}

main "$@"
