import React from 'react'

function ServiceCard({ service, loading, onStart, onStop, onViewLogs }) {
    const getStatusColor = () => {
        if (!service.running) return 'stopped'
        if (service.health === 'healthy') return 'healthy'
        if (service.health === 'unhealthy') return 'unhealthy'
        return 'starting'
    }

    const getStatusText = () => {
        if (!service.running) return 'Stopped'
        if (service.health === 'healthy') return 'Running'
        if (service.health === 'unhealthy') return 'Unhealthy'
        return 'Starting...'
    }

    const statusColor = getStatusColor()

    return (
        <div className={`service-card ${statusColor}`}>
            {/* Status Indicator */}
            <div className={`status-indicator ${statusColor}`}>
                <span className="status-dot"></span>
                <span className="status-text">{getStatusText()}</span>
            </div>

            {/* Service Info */}
            <div className="service-info">
                <h3 className="service-name">{service.name}</h3>
                <p className="container-name">{service.container_name}</p>
            </div>

            {/* Actions */}
            <div className="service-actions">
                {service.running ? (
                    <button
                        className="action-btn stop"
                        onClick={onStop}
                        disabled={loading === 'stop'}
                    >
                        {loading === 'stop' ? (
                            <span className="btn-spinner"></span>
                        ) : (
                            <>
                                <span className="btn-icon">⏹</span>
                                Stop
                            </>
                        )}
                    </button>
                ) : (
                    <button
                        className="action-btn start"
                        onClick={onStart}
                        disabled={loading === 'start'}
                    >
                        {loading === 'start' ? (
                            <span className="btn-spinner"></span>
                        ) : (
                            <>
                                <span className="btn-icon">▶</span>
                                Start
                            </>
                        )}
                    </button>
                )}

                <button className="action-btn logs" onClick={onViewLogs}>
                    <span className="btn-icon">📄</span>
                    Logs
                </button>

                {service.web_ui_url && (
                    <a
                        href={service.web_ui_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="action-btn web-ui"
                    >
                        <span className="btn-icon">🔗</span>
                        Web UI
                    </a>
                )}
            </div>
        </div>
    )
}

export default ServiceCard
