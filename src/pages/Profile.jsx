import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import './Profile.css'

const Profile = () => {
  const navigate = useNavigate()
  const [notificationsEnabled, setNotificationsEnabled] = useState(true)

  const handleLogout = () => {
    localStorage.removeItem('isAuthenticated')
    localStorage.removeItem('userEmail')
    localStorage.removeItem('userName')
    localStorage.removeItem('farmData')
    navigate('/login')
  }

  const toggleNotifications = () => {
    setNotificationsEnabled(!notificationsEnabled)
  }

  return (
    <div className="screen profile-screen">
      <h1 className="page-title">Mr. Uwimana</h1>

      <div className="profile-header">
        <div className="profile-avatar-large">👤</div>
        <h2>Mr. Uwimana</h2>
        <p>3 hectares • 15 seasons</p>
      </div>

      <div className="profile-stats">
        <div className="profile-stat">
          <h3>4</h3>
          <p>Years active</p>
        </div>
        <div className="profile-stat">
          <h3>87.5%</h3>
          <p>Success rate</p>
        </div>
        <div className="profile-stat">
          <h3>2</h3>
          <p>Crops grown</p>
        </div>
      </div>

      <div className="farm-info-card">
        <h3>Farm Information</h3>
        <div className="info-row">
          <span>Location</span>
          <strong>Bugesera District</strong>
        </div>
        <div className="info-row">
          <span>Province</span>
          <strong>Eastern Province</strong>
        </div>
        <div className="info-row">
          <span>Total Land</span>
          <strong>3 hectares</strong>
        </div>
        <div className="info-row">
          <span>Soil Type</span>
          <strong>Loamy clay</strong>
        </div>
      </div>

      <h3 className="section-title">SETTINGS</h3>

      <div className="settings-list">
        <button className="setting-item" onClick={toggleNotifications}>
          <span>🔔 Notifications</span>
          <div className={`toggle-switch ${notificationsEnabled ? 'active' : ''}`}>
            <div className="toggle-slider"></div>
          </div>
        </button>
        <button className="setting-item">
          <span>🔒 Security</span>
          <span className="chevron">›</span>
        </button>
        <button className="setting-item">
          <span>❓ Help</span>
          <span className="chevron">›</span>
        </button>
        <button className="setting-item logout-btn" onClick={handleLogout}>
          <span className="logout-text">🚪 Log out</span>
        </button>
      </div>

      <p className="version-text">Version 1.0.0 • BUILD 20250125</p>
    </div>
  )
}

export default Profile
