import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import './SeasonPlanning.css'
import { rwandaLocations, getDistricts, getSectors, getCells, getVillages } from '../data/rwandaLocations'
import DetailedRecommendationCard from '../components/DetailedRecommendationCard'

const SeasonPlanning = () => {
  const navigate = useNavigate()
  const [step, setStep] = useState(1)
  const [formData, setFormData] = useState({
    province: '',
    district: '',
    sector: '',
    cell: '',
    village: '',
    season: '',
    landType: '',
    landSize: ''
  })

  const handleInputChange = (field, value) => {
    setFormData(prev => {
      const updated = { ...prev, [field]: value }
      if (field === 'province') {
        updated.district = ''
        updated.sector = ''
        updated.cell = ''
        updated.village = ''
      } else if (field === 'district') {
        updated.sector = ''
        updated.cell = ''
        updated.village = ''
      } else if (field === 'sector') {
        updated.cell = ''
        updated.village = ''
      } else if (field === 'cell') {
        updated.village = ''
      }
      return updated
    })
  }

  const handleNext = () => {
    if (step === 1 && formData.province && formData.district && formData.sector && formData.cell && formData.village && formData.season) {
      setStep(2)
    } else if (step === 2 && formData.landType && formData.landSize) {
      setStep(3)
    }
  }

  const handleStartSeason = () => {
    localStorage.setItem('farmData', JSON.stringify(formData))
    navigate('/season')
  }

  return (
    <div className="screen season-planning-screen">
      <div className="planning-header">
        <button className="back-btn" onClick={() => navigate(-1)}>‹</button>
        <h1>New Season Planning</h1>
      </div>

      <div className="progress-indicator">
        <div className={`step-dot ${step >= 1 ? 'active' : ''}`}>1</div>
        <div className={`step-line ${step >= 2 ? 'active' : ''}`}></div>
        <div className={`step-dot ${step >= 2 ? 'active' : ''}`}>2</div>
        <div className={`step-line ${step >= 3 ? 'active' : ''}`}></div>
        <div className={`step-dot ${step >= 3 ? 'active' : ''}`}>3</div>
      </div>

      {step === 1 && (
        <div className="step-content">
          <div className="step-icon">📍</div>
          <h2>Location & Season</h2>
          <p>Tell us where and when you plan to cultivate</p>

          <div className="form-card">
            <div className="input-group">
              <label>Select your province</label>
              <select
                value={formData.province}
                onChange={(e) => handleInputChange('province', e.target.value)}
              >
                <option value="">Choose province</option>
                {Object.keys(rwandaLocations).map(province => (
                  <option key={province} value={province}>{province}</option>
                ))}
              </select>
            </div>

            {formData.province && (
              <div className="input-group">
                <label>Select your district</label>
                <select
                  value={formData.district}
                  onChange={(e) => handleInputChange('district', e.target.value)}
                >
                  <option value="">Choose district</option>
                  {getDistricts(formData.province).map(district => (
                    <option key={district} value={district}>{district}</option>
                  ))}
                </select>
              </div>
            )}

            {formData.district && (
              <div className="input-group">
                <label>Select your sector</label>
                <select
                  value={formData.sector}
                  onChange={(e) => handleInputChange('sector', e.target.value)}
                >
                  <option value="">Choose sector</option>
                  {getSectors(formData.province, formData.district).map(sector => (
                    <option key={sector} value={sector}>{sector}</option>
                  ))}
                </select>
              </div>
            )}

            {formData.sector && (
              <div className="input-group">
                <label>Select your cell</label>
                <select
                  value={formData.cell}
                  onChange={(e) => handleInputChange('cell', e.target.value)}
                >
                  <option value="">Choose cell</option>
                  {getCells(formData.province, formData.district, formData.sector).map(cell => (
                    <option key={cell} value={cell}>{cell}</option>
                  ))}
                </select>
              </div>
            )}

            {formData.cell && (
              <div className="input-group">
                <label>Select your village</label>
                <select
                  value={formData.village}
                  onChange={(e) => handleInputChange('village', e.target.value)}
                >
                  <option value="">Choose village</option>
                  {getVillages(formData.province, formData.district, formData.sector, formData.cell).map(village => (
                    <option key={village} value={village}>{village}</option>
                  ))}
                </select>
              </div>
            )}

            <div className="input-group">
              <label>Planting season</label>
              <select
                value={formData.season}
                onChange={(e) => handleInputChange('season', e.target.value)}
              >
                <option value="">Choose season</option>
                <option value="season-a">Season A (Sept - Jan)</option>
                <option value="season-b">Season B (Feb - June)</option>
              </select>
            </div>

            <div className="weather-preview">
              <h4>Expected Weather Conditions</h4>
              <div className="weather-stats">
                <div className="weather-stat">
                  <span>🌡️</span>
                  <div>
                    <strong>22-28°C</strong>
                    <p>Temperature</p>
                  </div>
                </div>
                <div className="weather-stat">
                  <span>💧</span>
                  <div>
                    <strong>800-1200mm</strong>
                    <p>Rainfall</p>
                  </div>
                </div>
              </div>
            </div>

            <button
              className="btn btn-primary full-width"
              onClick={handleNext}
              disabled={!formData.province || !formData.district || !formData.sector || !formData.cell || !formData.village || !formData.season}
            >
              Next Step
            </button>
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="step-content">
          <div className="step-icon">🌾</div>
          <h2>Land Details</h2>
          <p>Provide information about your farm land</p>

          <div className="form-card">
            <div className="input-group">
              <label>Land type</label>
              <select
                value={formData.landType}
                onChange={(e) => handleInputChange('landType', e.target.value)}
              >
                <option value="">Choose land type</option>
                <option value="wetland">Wetland (Marshland)</option>
                <option value="hillside">Hillside</option>
                <option value="valley">Valley Bottom</option>
                <option value="plateau">Plateau</option>
              </select>
            </div>

            <div className="input-group">
              <label>Land size (hectares)</label>
              <input
                type="number"
                placeholder="e.g., 2.5"
                value={formData.landSize}
                onChange={(e) => handleInputChange('landSize', e.target.value)}
              />
            </div>

            <div className="info-banner">
              <span>💡</span>
              <p>Land type and size help us recommend the best crops and calculate expected yields for your farm.</p>
            </div>

            <div className="button-group">
              <button
                className="btn btn-outline"
                onClick={() => setStep(1)}
              >
                Back
              </button>
              <button
                className="btn btn-primary"
                onClick={handleNext}
                disabled={!formData.landType || !formData.landSize}
              >
                Analyze
              </button>
            </div>
          </div>
        </div>
      )}

      {step === 3 && (
        <div className="step-content">
          <div className="step-icon success">✓</div>
          <h2>AI Analysis Complete</h2>
          <p>Based on your location and season, here are our recommendations</p>

          <div className="recommendation-results">
            <DetailedRecommendationCard
              crop="Rice"
              variety="DMIS variety"
              description={`Perfect match for ${formData.district} ${formData.landType} conditions. This variety thrives in Season B with expected high yields.`}
              growingPeriod="120-140 days"
              expectedYield="6-7 tons/ha"
              successRate="95%"
              badge="BEST MATCH"
            />

            <div className="result-card">
              <div className="result-header">
                <div className="result-icon">🌽</div>
                <div>
                  <h3>Maize (Hybrid)</h3>
                  <span className="badge" style={{background: 'rgba(255, 152, 0, 0.2)', color: 'var(--warning)'}}>Alternative</span>
                </div>
              </div>
              <p>Good alternative with moderate water needs. Suitable for hillside areas.</p>

              <div className="result-stats">
                <div className="stat-item">
                  <strong>90-110 days</strong>
                  <span>Growing period</span>
                </div>
                <div className="stat-item">
                  <strong>4-5 tons/ha</strong>
                  <span>Expected yield</span>
                </div>
              </div>
            </div>
          </div>

          <div className="weather-analysis">
            <h4>Weather Analysis</h4>
            <div className="analysis-item">
              <span className="analysis-icon success">✓</span>
              <div>
                <strong>Rainfall Pattern: Optimal</strong>
                <p>Expected rainfall of 900-1100mm matches rice water requirements perfectly</p>
              </div>
            </div>
            <div className="analysis-item">
              <span className="analysis-icon success">✓</span>
              <div>
                <strong>Temperature: Ideal</strong>
                <p>Average temperature of 24-26°C is ideal for rice cultivation</p>
              </div>
            </div>
            <div className="analysis-item">
              <span className="analysis-icon warning">!</span>
              <div>
                <strong>Risk Factor: Medium</strong>
                <p>Monitor for potential pest pressure during mid-season. Preventive measures recommended.</p>
              </div>
            </div>
          </div>

          <button
            className="btn btn-primary full-width"
            onClick={handleStartSeason}
          >
            Start Season with Rice
          </button>
        </div>
      )}
    </div>
  )
}

export default SeasonPlanning
