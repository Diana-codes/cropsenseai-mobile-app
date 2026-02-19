import './Season.css'

const Season = () => {
  return (
    <div className="screen season-screen">
      <h1 className="page-title">Season</h1>

      <div className="current-season-card">
        <div className="season-icon">🌾</div>
        <div className="season-info">
          <span className="badge badge-success">In progress</span>
          <h3>WINTER: SPRING RICE</h3>
          <p>📅 Rice • Field A2 (2ha)</p>
        </div>
        <div className="season-arrow">›</div>
      </div>

      <div className="progress-card">
        <p>Phase progress</p>
        <h2>16%</h2>
      </div>

      <div className="time-cards">
        <div className="time-card">
          <h3>10 days</h3>
          <p>GDD</p>
        </div>
        <div className="time-card">
          <h3>15 days</h3>
          <p>Elapsed</p>
        </div>
      </div>

      <div className="achievement-card">
        <div className="achievement-header">
          <div className="trophy-icon">🏆</div>
          <h4>EXCELLENT FARMER</h4>
        </div>
        <p>Achieved over 95% productivity for 3 consecutive seasons</p>
      </div>

      <h3 className="section-title">OVERVIEW STATISTICS</h3>

      <div className="stats-grid">
        <div className="stat-card">
          <h3>4</h3>
          <p>Years of field data</p>
        </div>
        <div className="stat-card">
          <h3>2</h3>
          <p>Crops planted</p>
        </div>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <h3 className="stat-primary">87.5%</h3>
          <p>Average productivity</p>
        </div>
        <div className="stat-card">
          <h3 className="stat-primary">8.2%</h3>
          <p>Income increase</p>
        </div>
      </div>

      <h3 className="section-title">CONTACT INFORMATION</h3>

      <div className="contact-list">
        <div className="contact-item">
          <span className="contact-icon">📞</span>
          <p>+250 788 123 456</p>
        </div>
        <div className="contact-item">
          <span className="contact-icon">✉️</span>
          <p>uwimana@email.rw</p>
        </div>
        <div className="contact-item">
          <span className="contact-icon">📍</span>
          <p>Bugesera District, Eastern Province, Rwanda</p>
        </div>
      </div>
    </div>
  )
}

export default Season
