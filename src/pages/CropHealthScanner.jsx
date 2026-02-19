import { useNavigate } from 'react-router-dom'
import './CropHealthScanner.css'

const CropHealthScanner = () => {
  const navigate = useNavigate()

  return (
    <div className="screen scanner-screen">
      <div className="scanner-header">
        <button className="back-btn" onClick={() => navigate(-1)}>‹</button>
        <h1>Crop Health Scanner</h1>
      </div>

      <div className="scanner-intro-card">
        <div className="scanner-icon">📷</div>
        <div>
          <h3>Scan Your Crop</h3>
          <p>Upload crop image</p>
        </div>
      </div>

      <div className="upload-card">
        <div className="upload-area">
          <div className="upload-placeholder">
            <span className="upload-icon">🖼️</span>
            <p>Upload a photo</p>
          </div>
        </div>
        <div className="upload-actions">
          <button className="btn btn-primary upload-btn">
            📷 Take Photo
          </button>
          <button className="btn btn-outline upload-btn">
            📁 Upload
          </button>
        </div>
      </div>

      <h3 className="section-title">Disease Detection</h3>

      <div className="detection-card">
        <div className="detection-icon">🔍</div>
        <div>
          <h4>Identify health issues</h4>
          <p>Get real-time treatment recommendations</p>
        </div>
      </div>

      <h3 className="section-title">Common Crop Diseases</h3>

      <div className="disease-card">
        <div className="disease-header">
          <h4>Rice Blast</h4>
          <span className="badge badge-danger">High Risk</span>
        </div>
        <p>Causes lesions on leaves, stems, and panicles. Most severe in high humidity with moderate temperatures.</p>
      </div>

      <div className="disease-card">
        <div className="disease-header">
          <h4>Bacterial Leaf Blight</h4>
          <span className="badge badge-warning">Medium Risk</span>
        </div>
        <p>Water-soaked lesions along leaf margins with yellowish halos that spread and create wilted appearance.</p>
      </div>

      <div className="disease-card">
        <div className="disease-header">
          <h4>Leaf Spot</h4>
          <span className="badge badge-warning">Medium Risk</span>
        </div>
        <p>Small brown spots with light centers on leaves. Can affect multiple leaf margins.</p>
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

export default CropHealthScanner
