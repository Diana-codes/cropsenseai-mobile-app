import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import Home from './pages/Home'
import Process from './pages/Process'
import Season from './pages/Season'
import SeasonPlanning from './pages/SeasonPlanning'
import Profile from './pages/Profile'
import AIAdvisor from './pages/AIAdvisor'
import CropHealthScanner from './pages/CropHealthScanner'
import Login from './pages/Login'
import Register from './pages/Register'
import BottomNav from './components/BottomNav'
import './App.css'

const ProtectedRoute = ({ children }) => {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true'
  return isAuthenticated ? children : <Navigate to="/login" replace />
}

const AuthRoute = ({ children }) => {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true'
  return isAuthenticated ? <Navigate to="/" replace /> : children
}

const AppContent = () => {
  const location = useLocation()
  const hideNav = location.pathname === '/login' || location.pathname === '/register'

  return (
    <div className="mobile-container">
      <Routes>
        <Route path="/login" element={<AuthRoute><Login /></AuthRoute>} />
        <Route path="/register" element={<AuthRoute><Register /></AuthRoute>} />
        <Route path="/" element={<ProtectedRoute><Home /></ProtectedRoute>} />
        <Route path="/process" element={<ProtectedRoute><Process /></ProtectedRoute>} />
        <Route path="/season" element={<ProtectedRoute><Season /></ProtectedRoute>} />
        <Route path="/season-planning" element={<ProtectedRoute><SeasonPlanning /></ProtectedRoute>} />
        <Route path="/profile" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
        <Route path="/ai-advisor" element={<ProtectedRoute><AIAdvisor /></ProtectedRoute>} />
        <Route path="/crop-scanner" element={<ProtectedRoute><CropHealthScanner /></ProtectedRoute>} />
      </Routes>
      {!hideNav && <BottomNav />}
    </div>
  )
}

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  )
}

export default App
