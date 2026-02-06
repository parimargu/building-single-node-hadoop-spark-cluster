import React from 'react'

function Header({ darkMode, toggleDarkMode }) {
    return (
        <header className="header">
            <div className="header-content">
                <div className="logo-section">
                    <div className="logo">
                        <span className="logo-icon">🔷</span>
                        <span className="logo-text">Big Data Cluster Monitor</span>
                    </div>
                    <span className="version-badge">v1.0</span>
                </div>

                <div className="header-actions">
                    <div className="cluster-status">
                        <span className="status-dot active"></span>
                        <span className="status-text">Cluster Active</span>
                    </div>

                    <button
                        className="theme-toggle"
                        onClick={toggleDarkMode}
                        aria-label="Toggle dark mode"
                    >
                        {darkMode ? '☀️' : '🌙'}
                    </button>
                </div>
            </div>
        </header>
    )
}

export default Header
