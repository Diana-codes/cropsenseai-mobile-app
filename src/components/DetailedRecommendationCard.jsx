import './DetailedRecommendationCard.css'

const DetailedRecommendationCard = ({ crop, variety, description, growingPeriod, expectedYield, successRate, badge }) => {
  return (
    <div className="detailed-rec-card">
      <div className="detailed-rec-header">
        <div className="crop-icon-large">🌾</div>
        <div className="crop-header-info">
          <h3>{crop} ({variety})</h3>
          {badge && <span className="rec-badge best-match">{badge}</span>}
        </div>
      </div>

      <p className="crop-description">{description}</p>

      <div className="crop-stats-grid">
        <div className="crop-stat">
          <div className="stat-value">{growingPeriod}</div>
          <div className="stat-label">Growing period</div>
        </div>
        <div className="crop-stat">
          <div className="stat-value">{expectedYield}</div>
          <div className="stat-label">Expected yield</div>
        </div>
        <div className="crop-stat">
          <div className="stat-value success-rate">{successRate}</div>
          <div className="stat-label">Success rate</div>
        </div>
      </div>
    </div>
  )
}

export default DetailedRecommendationCard
