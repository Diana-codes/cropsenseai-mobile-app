import { useNavigate } from 'react-router-dom'
import { useState } from 'react'
import WeatherCard from '../components/WeatherCard'
import './Home.css'

const Home = () => {
  const navigate = useNavigate()
  const [showAllRecommendations, setShowAllRecommendations] = useState(false)

  const weatherForecast = [
    { day: 'Mon', icon: '☀️', temp: 24 },
    { day: 'Tue', icon: '⛅', temp: 23 },
    { day: 'Wed', icon: '🌤️', temp: 25 },
    { day: 'Thu', icon: '☀️', temp: 26 },
    { day: 'Fri', icon: '⛅', temp: 27 }
  ]

  const allRecommendations = [
    {
      icon: '🌾',
      title: 'Rice (DMIS variety)',
      description: 'Best choice for current season conditions',
      badges: [
        { text: '120-140 days', type: 'default' },
        { text: 'High confidence', type: 'success' }
      ]
    },
    {
      icon: '🌽',
      title: 'Maize (Hybrid variety)',
      description: 'Good alternative with lower water needs',
      badges: [
        { text: '90-110 days', type: 'default' },
        { text: 'Medium confidence', type: 'warning' }
      ]
    },
    {
      icon: '🫘',
      title: 'Beans (Climbing variety)',
      description: 'Excellent for intercropping and soil health',
      badges: [
        { text: '75-90 days', type: 'default' },
        { text: 'High confidence', type: 'success' }
      ]
    },
    {
      icon: '🥔',
      title: 'Irish Potato',
      description: 'High demand and good market prices',
      badges: [
        { text: '90-120 days', type: 'default' },
        { text: 'Medium confidence', type: 'warning' }
      ]
    }
  ]

  const displayedRecommendations = showAllRecommendations
    ? allRecommendations
    : allRecommendations.slice(0, 2)

  return (
    <div className="screen home-screen">
      <div className="user-header">
        <div>
          <h1 className="user-name">Mr. Uwimana</h1>
          <p className="user-location">Bugesera District, Eastern Province</p>
        </div>
        <div className="user-avatar">👤</div>
      </div>

      <WeatherCard
        location="Bugesera, Rwanda"
        temperature={24}
        condition="☁️ Partly Cloudy"
        humidity={65}
        windSpeed={12}
        forecast={weatherForecast}
      />

      <h3 className="section-title">Quick Actions</h3>
      <div className="quick-actions-grid">
        <button className="quick-action-btn" onClick={() => navigate('/season-planning')}>
          <div className="action-icon" style={{background: 'rgba(76, 175, 80, 0.1)'}}>
            <span style={{color: 'var(--primary)'}}>➕</span>
          </div>
          <div className="action-text">
            <h4>New Season</h4>
            <p>Start planning</p>
          </div>
        </button>

        <button className="quick-action-btn" onClick={() => navigate('/crop-scanner')}>
          <div className="action-icon" style={{background: 'rgba(255, 152, 0, 0.1)'}}>
            <span style={{color: 'var(--warning)'}}>🌾</span>
          </div>
          <div className="action-text">
            <h4>Crop Health</h4>
            <p>Scan crops</p>
          </div>
        </button>

        <button className="quick-action-btn" onClick={() => navigate('/ai-advisor')}>
          <div className="action-icon" style={{background: 'rgba(156, 39, 176, 0.1)'}}>
            <span style={{color: 'var(--purple)'}}>💡</span>
          </div>
          <div className="action-text">
            <h4>Get Advice</h4>
            <p>AI advisor</p>
          </div>
        </button>

        <button className="quick-action-btn" onClick={() => navigate('/process')}>
          <div className="action-icon" style={{background: 'rgba(33, 150, 243, 0.1)'}}>
            <span style={{color: 'var(--info)'}}>📋</span>
          </div>
          <div className="action-text">
            <h4>My Process</h4>
            <p>View stages</p>
          </div>
        </button>
      </div>

      <h3 className="section-title">Alerts & Recommendations</h3>
      <div className="alert-card warning">
        <div className="alert-icon">⚠️</div>
        <div className="alert-content">
          <h4>Heavy rainfall expected</h4>
          <p>This week: Postpone planting until water...</p>
          <button className="alert-action">Prepare field</button>
        </div>
      </div>

      <div className="recommendations-header">
        <h3 className="section-title">Recommended for</h3>
        <button
          className="see-all-btn"
          onClick={() => setShowAllRecommendations(!showAllRecommendations)}
        >
          {showAllRecommendations ? 'Show less' : 'See all'}
        </button>
      </div>
      <p className="section-subtitle">This season</p>

      {displayedRecommendations.map((rec, index) => (
        <div key={index} className="recommendation-card">
          <div className="rec-icon">{rec.icon}</div>
          <div className="rec-content">
            <h4>{rec.title}</h4>
            <p>{rec.description}</p>
            <div className="rec-badges">
              {rec.badges.map((badge, idx) => (
                <span
                  key={idx}
                  className={`badge ${badge.type === 'success' ? 'badge-success' : badge.type === 'warning' ? 'badge-warning' : ''}`}
                >
                  {badge.text}
                </span>
              ))}
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}

export default Home
