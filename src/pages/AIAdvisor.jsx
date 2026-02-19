import { useNavigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import './AIAdvisor.css'
import { rwandaLocations, getDistricts, getSectors, getCells, getVillages } from '../data/rwandaLocations'

const AIAdvisor = () => {
  const navigate = useNavigate()
  const [showRecommendations, setShowRecommendations] = useState(false)
  const [formData, setFormData] = useState({
    province: '',
    district: '',
    sector: '',
    cell: '',
    village: '',
    season: '',
    landType: ''
  })

  useEffect(() => {
    const savedData = localStorage.getItem('farmData')
    if (savedData) {
      const parsed = JSON.parse(savedData)
      setFormData({
        province: parsed.province || '',
        district: parsed.district || '',
        sector: parsed.sector || '',
        cell: parsed.cell || '',
        village: parsed.village || '',
        season: parsed.season || '',
        landType: parsed.landType || ''
      })
    }
  }, [])

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

  const handleGetRecommendations = () => {
    if (formData.province && formData.district && formData.sector && formData.cell && formData.village && formData.season && formData.landType) {
      setShowRecommendations(true)
    }
  }

  return (
    <div className="screen ai-advisor-screen">
      <div className="advisor-header">
        <button className="back-btn" onClick={() => navigate(-1)}>‹</button>
        <h1>AI Crop Advisor</h1>
      </div>

      <div className="advisor-intro-card">
        <div className="advisor-icon">🌱</div>
        <div>
          <h3>CropSense AI</h3>
          <p>Your personalized crop recommendation assistant based on your location, soil conditions, and historical data to recommend the best crops for you.</p>
        </div>
      </div>

      <div className="input-card">
        <h4>Tell us about your farm</h4>
        <div className="input-group">
          <label>Province</label>
          <select value={formData.province} onChange={(e) => handleInputChange('province', e.target.value)}>
            <option value="">Select your province</option>
            {Object.keys(rwandaLocations).map(province => (
              <option key={province} value={province}>{province}</option>
            ))}
          </select>
        </div>

        {formData.province && (
          <div className="input-group">
            <label>District</label>
            <select value={formData.district} onChange={(e) => handleInputChange('district', e.target.value)}>
              <option value="">Select your district</option>
              {getDistricts(formData.province).map(district => (
                <option key={district} value={district}>{district}</option>
              ))}
            </select>
          </div>
        )}

        {formData.district && (
          <div className="input-group">
            <label>Sector</label>
            <select value={formData.sector} onChange={(e) => handleInputChange('sector', e.target.value)}>
              <option value="">Select your sector</option>
              {getSectors(formData.province, formData.district).map(sector => (
                <option key={sector} value={sector}>{sector}</option>
              ))}
            </select>
          </div>
        )}

        {formData.sector && (
          <div className="input-group">
            <label>Cell</label>
            <select value={formData.cell} onChange={(e) => handleInputChange('cell', e.target.value)}>
              <option value="">Select your cell</option>
              {getCells(formData.province, formData.district, formData.sector).map(cell => (
                <option key={cell} value={cell}>{cell}</option>
              ))}
            </select>
          </div>
        )}

        {formData.cell && (
          <div className="input-group">
            <label>Village</label>
            <select value={formData.village} onChange={(e) => handleInputChange('village', e.target.value)}>
              <option value="">Select your village</option>
              {getVillages(formData.province, formData.district, formData.sector, formData.cell).map(village => (
                <option key={village} value={village}>{village}</option>
              ))}
            </select>
          </div>
        )}

        <div className="input-group">
          <label>Season planning season</label>
          <select value={formData.season} onChange={(e) => handleInputChange('season', e.target.value)}>
            <option value="">Select season</option>
            <option value="season-a">Season A (Sept - Jan)</option>
            <option value="season-b">Season B (Feb - June)</option>
          </select>
        </div>
        <div className="input-group">
          <label>Select land type</label>
          <select value={formData.landType} onChange={(e) => handleInputChange('landType', e.target.value)}>
            <option value="">Select land type</option>
            <option value="wetland">Wetland</option>
            <option value="hillside">Hillside</option>
            <option value="valley">Valley</option>
            <option value="plateau">Plateau</option>
          </select>
        </div>
        <button
          className="btn btn-primary full-width"
          onClick={handleGetRecommendations}
          disabled={!formData.province || !formData.district || !formData.sector || !formData.cell || !formData.village || !formData.season || !formData.landType}
        >
          Get AI Cultivation Guide
        </button>
      </div>

      {showRecommendations && (
        <>
          <h3 className="section-title">AI Recommendations</h3>

          <div className="alt-option-card featured">
            <div className="alt-header">
              <h4>Rice (DMIS Variety)</h4>
              <span className="badge badge-success">Best Match</span>
            </div>
            <p>Excellent match for {formData.landType} in {formData.district}. Proven resilient to weather patterns in similar conditions.</p>
            <div className="alt-details">
              <span>🕐 120-140 days</span>
              <span>💧 6-7 tons/ha</span>
              <span>✓ High success rate</span>
            </div>
          </div>

          <div className="alt-option-card">
            <div className="alt-header">
              <h4>Maize (Hybrid variety)</h4>
              <span className="badge badge-info">Alternative</span>
            </div>
            <p>Works best in your location with similar duration. Moderate water needs. Good for rotation crops.</p>
            <div className="alt-details">
              <span>🕐 90-110 days</span>
              <span>💧 4-5 tons/ha</span>
            </div>
          </div>

          <div className="alt-option-card">
            <div className="alt-header">
              <h4>Beans (Climbing variety)</h4>
              <span className="badge badge-info">Alternative</span>
            </div>
            <p>Excellent for intercropping and soil enrichment. Low water requirements.</p>
            <div className="alt-details">
              <span>🕐 75-90 days</span>
              <span>💧 1-2 tons/ha</span>
            </div>
          </div>
        </>
      )}

      <h3 className="section-title">How to Take Good Photos</h3>

      <div className="tip-card">
        <div className="tip-number" style={{background: 'rgba(76, 175, 80, 0.1)', color: 'var(--primary)'}}>1</div>
        <div>
          <h4>Good Lighting</h4>
          <p>Take the photo in natural light; avoid dark or shaded areas for best results</p>
        </div>
      </div>

      <div className="tip-card">
        <div className="tip-number" style={{background: 'rgba(33, 150, 243, 0.1)', color: 'var(--info)'}}>2</div>
        <div>
          <h4>Clear Focus</h4>
          <p>Ensure that the camera is steady and focus on the leaf clearly with sharp details</p>
        </div>
      </div>

      <div className="tip-card">
        <div className="tip-number" style={{background: 'rgba(156, 39, 176, 0.1)', color: 'var(--purple)'}}>3</div>
        <div>
          <h4>Multiple Angles</h4>
          <p>Take 2-3 photos from different angles. AI analyzes from multiple perspectives</p>
        </div>
      </div>

      <div className="coming-soon-banner">
        <span>ℹ️</span>
        <div>
          <h4>AI Feature Coming Soon</h4>
          <p>Automatic disease detection and treatment recommendations will be available in the next version.</p>
        </div>
      </div>

      <button className="btn btn-primary full-width">Next Steps</button>
    </div>
  )
}

export default AIAdvisor
