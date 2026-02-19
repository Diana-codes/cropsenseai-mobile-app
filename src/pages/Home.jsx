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

        <button className="quick-action-btn" onClick={() => navigate('/process')}>
          <div className="action-icon" style={{background: 'rgba(244, 67, 54, 0.1)'}}>
            <span style={{color: '#f44336'}}>💼</span>
          </div>
          <div className="action-text">
            <h4>Track Jobs</h4>
            <p>Monitor tasks</p>
          </div>
        </button>
      </div>
    </div>
  )
}

export default Home
