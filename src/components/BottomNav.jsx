import { useLocation, useNavigate } from 'react-router-dom'
import './BottomNav.css'

const BottomNav = () => {
  const location = useLocation()
  const navigate = useNavigate()

  const hideNavPaths = ['/ai-advisor', '/crop-scanner', '/season-planning']
  if (hideNavPaths.includes(location.pathname)) {
    return null
  }

  const navItems = [
    { path: '/', icon: '🏠', label: 'Home' },
    { path: '/process', icon: '📋', label: 'Process' },
    { path: '/season', icon: '🌱', label: 'Season' },
    { path: '/profile', icon: '👤', label: 'Profile' }
  ]

  return (
    <nav className="bottom-nav">
      {navItems.map((item) => (
        <button
          key={item.path}
          className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
          onClick={() => navigate(item.path)}
        >
          <span className="nav-icon">{item.icon}</span>
          <span className="nav-label">{item.label}</span>
        </button>
      ))}
    </nav>
  )
}

export default BottomNav
