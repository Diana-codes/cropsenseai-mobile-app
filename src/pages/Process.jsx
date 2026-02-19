import './Process.css'

const Process = () => {
  const stages = [
    {
      id: 1,
      title: 'Soil preparation',
      status: 'completed',
      progress: 100,
      duration: '7 days',
      tasks: [
        { text: 'Land preparation in flooded and tilled soil', done: true },
        { text: 'Apply fertilizers', done: true }
      ],
      notes: {
        heading: 'Technical notes',
        content: 'Land preparation is the foundation for good rice establishment. It should end over time threshed and tilled drainage.',
        quality: [
          'Proper plowing and puddling optimize seedling establishment',
          'Remove all debris and maintain standing water at 5cm',
          'Form channels from the previous crop',
          'Organic matter into soil'
        ]
      }
    },
    {
      id: 2,
      title: 'Clear weeds and crop residue',
      status: 'in-progress',
      progress: 65,
      duration: '5 days',
      warning: 'Do not plow deep to maintain root structures weeds and the top of the incorporated weeds that reduces moisture.',
      notes: {
        content: 'Now: Delay planting due to adverse grain growth, seed germination, and poor crop residue has potential'
      }
    },
    {
      id: 3,
      title: 'Planting',
      status: 'upcoming',
      progress: 0,
      duration: '10 days'
    },
    {
      id: 4,
      title: 'Growth & Maintenance',
      status: 'upcoming',
      progress: 0,
      duration: '90 days'
    },
    {
      id: 5,
      title: 'Harvesting',
      status: 'upcoming',
      progress: 0,
      duration: '14 days'
    },
    {
      id: 6,
      title: 'Post-harvest',
      status: 'upcoming',
      progress: 0,
      duration: '7 days'
    }
  ]

  const completedStages = stages.filter(s => s.status === 'completed').length
  const overallProgress = Math.round((completedStages / stages.length) * 100)

  return (
    <div className="screen process-screen">
      <h1 className="page-title">Process</h1>

      <div className="process-header-card">
        <div className="process-icon">🌾</div>
        <div className="process-info">
          <h3>WET RICE CULTIVATION</h3>
          <p>Traditional daily rice cultivation process in flooded fields</p>
        </div>
      </div>

      <div className="overall-progress-card">
        <div className="progress-info">
          <h4>Overall Progress</h4>
          <span className="progress-percentage">{overallProgress}%</span>
        </div>
        <div className="progress-bar-container">
          <div className="progress-bar-fill" style={{width: `${overallProgress}%`}}></div>
        </div>
        <p className="progress-text">{completedStages} of {stages.length} stages completed</p>
      </div>

      <div className="overview-section">
        <h4>Overview</h4>
        <div className="overview-details">
          <div className="detail-row">
            <span>Duration</span>
            <strong>120-140 days</strong>
          </div>
          <div className="detail-row">
            <span>Area</span>
            <strong>Field A2 (2 hectares)</strong>
          </div>
          <div className="detail-row">
            <span>Start Date</span>
            <strong>Jan 15, 2026</strong>
          </div>
          <div className="detail-row">
            <span>Seed Variety</span>
            <strong>DMIS variety</strong>
          </div>
          <div className="detail-row">
            <span>Expected Yield</span>
            <strong>6-7 tons/hectare</strong>
          </div>
        </div>
      </div>

      <h3 className="section-title">Stages</h3>

      <div className="stages-list">
        {stages.map((stage) => (
          <div key={stage.id} className={`stage-card ${stage.status}`}>
            <div className="stage-header">
              <div className="stage-number">{stage.id}</div>
              <div className="stage-title-group">
                <h4>{stage.title}</h4>
                <span className="stage-duration">{stage.duration}</span>
              </div>
              <span className={`status-badge ${stage.status}`}>
                {stage.status === 'completed' && '✓'}
                {stage.status === 'in-progress' && '⏳'}
                {stage.status === 'upcoming' && '○'}
              </span>
            </div>

            {stage.status !== 'upcoming' && (
              <div className="stage-progress">
                <div className="stage-progress-bar">
                  <div
                    className={`stage-progress-fill ${stage.status}`}
                    style={{width: `${stage.progress}%`}}
                  ></div>
                </div>
                <span className="stage-progress-text">{stage.progress}%</span>
              </div>
            )}

            {stage.tasks && (
              <div className="stage-tasks">
                {stage.tasks.map((task, idx) => (
                  <div key={idx} className="task-item">
                    <input type="checkbox" checked={task.done} readOnly />
                    <span>{task.text}</span>
                  </div>
                ))}
              </div>
            )}

            {stage.warning && (
              <div className="stage-warning">
                <span>⚠️</span>
                <p>{stage.warning}</p>
              </div>
            )}

            {stage.notes && (
              <div className="stage-notes">
                {stage.notes.heading && <h5>{stage.notes.heading}</h5>}
                <p>{stage.notes.content}</p>
                {stage.notes.quality && (
                  <div className="quality-standards">
                    <h5>Quality standards</h5>
                    <ul>
                      {stage.notes.quality.map((item, idx) => (
                        <li key={idx}>{item}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

export default Process
