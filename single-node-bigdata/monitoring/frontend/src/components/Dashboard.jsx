import React from 'react'
import ServiceCard from './ServiceCard'

const SERVICE_GROUPS = [
    { name: 'Hadoop', type: 'hadoop', icon: '🐘' },
    { name: 'Spark', type: 'spark', icon: '⚡' },
    { name: 'Hive', type: 'hive', icon: '🐝' },
    { name: 'Databases', type: 'database', icon: '🗄️' }
]

function Dashboard({ services, loading, actionLoading, onStart, onStop, onViewLogs }) {
    if (loading) {
        return (
            <div className="loading-container">
                <div className="loading-spinner"></div>
                <p>Loading services...</p>
            </div>
        )
    }

    // Group services by type
    const groupedServices = SERVICE_GROUPS.map(group => ({
        ...group,
        services: services.filter(s => s.service_type === group.type)
    }))

    // Calculate statistics
    const totalServices = services.length
    const runningServices = services.filter(s => s.running).length
    const healthyServices = services.filter(s => s.health === 'healthy').length

    return (
        <div className="dashboard">
            {/* Statistics Cards */}
            <div className="stats-container">
                <div className="stat-card">
                    <div className="stat-icon total">📊</div>
                    <div className="stat-info">
                        <span className="stat-value">{totalServices}</span>
                        <span className="stat-label">Total Services</span>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon running">▶️</div>
                    <div className="stat-info">
                        <span className="stat-value">{runningServices}</span>
                        <span className="stat-label">Running</span>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon healthy">💚</div>
                    <div className="stat-info">
                        <span className="stat-value">{healthyServices}</span>
                        <span className="stat-label">Healthy</span>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon stopped">⏸️</div>
                    <div className="stat-info">
                        <span className="stat-value">{totalServices - runningServices}</span>
                        <span className="stat-label">Stopped</span>
                    </div>
                </div>
            </div>

            {/* Service Groups */}
            {groupedServices.map(group => (
                group.services.length > 0 && (
                    <div key={group.type} className="service-group">
                        <h2 className="group-title">
                            <span className="group-icon">{group.icon}</span>
                            {group.name}
                            <span className="group-count">{group.services.length}</span>
                        </h2>
                        <div className="services-grid">
                            {group.services.map(service => (
                                <ServiceCard
                                    key={service.container_name}
                                    service={service}
                                    loading={actionLoading[service.container_name]}
                                    onStart={() => onStart(service.container_name)}
                                    onStop={() => onStop(service.container_name)}
                                    onViewLogs={() => onViewLogs(service)}
                                />
                            ))}
                        </div>
                    </div>
                )
            ))}
        </div>
    )
}

export default Dashboard
