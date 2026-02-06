import React, { useState, useEffect, useCallback } from 'react'
import Header from './components/Header'
import Dashboard from './components/Dashboard'
import LogsModal from './components/LogsModal'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

function App() {
    const [services, setServices] = useState([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)
    const [darkMode, setDarkMode] = useState(() => {
        const saved = localStorage.getItem('darkMode')
        return saved ? JSON.parse(saved) : window.matchMedia('(prefers-color-scheme: dark)').matches
    })
    const [logsModal, setLogsModal] = useState({ open: false, service: null })
    const [actionLoading, setActionLoading] = useState({})

    // Apply dark mode class to document
    useEffect(() => {
        document.documentElement.classList.toggle('dark', darkMode)
        localStorage.setItem('darkMode', JSON.stringify(darkMode))
    }, [darkMode])

    // Fetch services
    const fetchServices = useCallback(async () => {
        try {
            const response = await fetch(`${API_URL}/services`)
            if (!response.ok) throw new Error('Failed to fetch services')
            const data = await response.json()
            setServices(data.services || [])
            setError(null)
        } catch (err) {
            setError(err.message)
        } finally {
            setLoading(false)
        }
    }, [])

    // Initial fetch and polling
    useEffect(() => {
        fetchServices()
        const interval = setInterval(fetchServices, 10000)
        return () => clearInterval(interval)
    }, [fetchServices])

    // Start service
    const startService = async (containerName) => {
        setActionLoading(prev => ({ ...prev, [containerName]: 'start' }))
        try {
            const response = await fetch(`${API_URL}/services/${containerName}/start`, {
                method: 'POST'
            })
            if (!response.ok) throw new Error('Failed to start service')
            await fetchServices()
        } catch (err) {
            setError(err.message)
        } finally {
            setActionLoading(prev => ({ ...prev, [containerName]: null }))
        }
    }

    // Stop service
    const stopService = async (containerName) => {
        setActionLoading(prev => ({ ...prev, [containerName]: 'stop' }))
        try {
            const response = await fetch(`${API_URL}/services/${containerName}/stop`, {
                method: 'POST'
            })
            if (!response.ok) throw new Error('Failed to stop service')
            await fetchServices()
        } catch (err) {
            setError(err.message)
        } finally {
            setActionLoading(prev => ({ ...prev, [containerName]: null }))
        }
    }

    // Open logs modal
    const openLogs = (service) => {
        setLogsModal({ open: true, service })
    }

    // Close logs modal
    const closeLogs = () => {
        setLogsModal({ open: false, service: null })
    }

    return (
        <div className="app">
            <Header
                darkMode={darkMode}
                toggleDarkMode={() => setDarkMode(!darkMode)}
            />

            <main className="main-content">
                {error && (
                    <div className="error-banner">
                        <span className="error-icon">⚠️</span>
                        <span>{error}</span>
                        <button onClick={() => setError(null)} className="dismiss-btn">×</button>
                    </div>
                )}

                <Dashboard
                    services={services}
                    loading={loading}
                    actionLoading={actionLoading}
                    onStart={startService}
                    onStop={stopService}
                    onViewLogs={openLogs}
                />
            </main>

            {logsModal.open && (
                <LogsModal
                    service={logsModal.service}
                    apiUrl={API_URL}
                    onClose={closeLogs}
                />
            )}
        </div>
    )
}

export default App
