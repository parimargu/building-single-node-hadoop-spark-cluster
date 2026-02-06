import React, { useState, useEffect, useRef } from 'react'

function LogsModal({ service, apiUrl, onClose }) {
    const [logs, setLogs] = useState('')
    const [loading, setLoading] = useState(true)
    const [autoRefresh, setAutoRefresh] = useState(true)
    const [tail, setTail] = useState(100)
    const logsRef = useRef(null)

    // Fetch logs
    const fetchLogs = async () => {
        try {
            const response = await fetch(
                `${apiUrl}/services/${service.container_name}/logs?tail=${tail}`
            )
            if (!response.ok) throw new Error('Failed to fetch logs')
            const data = await response.json()
            setLogs(data.logs || 'No logs available')
        } catch (err) {
            setLogs(`Error fetching logs: ${err.message}`)
        } finally {
            setLoading(false)
        }
    }

    // Initial fetch and auto-refresh
    useEffect(() => {
        fetchLogs()

        if (autoRefresh) {
            const interval = setInterval(fetchLogs, 5000)
            return () => clearInterval(interval)
        }
    }, [autoRefresh, tail])

    // Auto-scroll to bottom
    useEffect(() => {
        if (logsRef.current) {
            logsRef.current.scrollTop = logsRef.current.scrollHeight
        }
    }, [logs])

    // Handle escape key
    useEffect(() => {
        const handleEscape = (e) => {
            if (e.key === 'Escape') onClose()
        }
        document.addEventListener('keydown', handleEscape)
        return () => document.removeEventListener('keydown', handleEscape)
    }, [onClose])

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content" onClick={e => e.stopPropagation()}>
                {/* Modal Header */}
                <div className="modal-header">
                    <div className="modal-title">
                        <span className="modal-icon">📄</span>
                        <span>Logs: {service.name}</span>
                        <span className="container-badge">{service.container_name}</span>
                    </div>
                    <button className="close-btn" onClick={onClose}>×</button>
                </div>

                {/* Modal Controls */}
                <div className="modal-controls">
                    <div className="control-group">
                        <label>
                            <span>Lines:</span>
                            <select
                                value={tail}
                                onChange={(e) => setTail(Number(e.target.value))}
                            >
                                <option value={50}>50</option>
                                <option value={100}>100</option>
                                <option value={200}>200</option>
                                <option value={500}>500</option>
                            </select>
                        </label>
                    </div>

                    <div className="control-group">
                        <label className="toggle-label">
                            <input
                                type="checkbox"
                                checked={autoRefresh}
                                onChange={(e) => setAutoRefresh(e.target.checked)}
                            />
                            <span>Auto-refresh</span>
                        </label>
                    </div>

                    <button className="refresh-btn" onClick={fetchLogs}>
                        🔄 Refresh
                    </button>
                </div>

                {/* Logs Content */}
                <div className="logs-container" ref={logsRef}>
                    {loading ? (
                        <div className="logs-loading">
                            <div className="loading-spinner"></div>
                            <p>Loading logs...</p>
                        </div>
                    ) : (
                        <pre className="logs-content">{logs}</pre>
                    )}
                </div>
            </div>
        </div>
    )
}

export default LogsModal
