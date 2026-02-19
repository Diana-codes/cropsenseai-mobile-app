import './WeatherCard.css'

const WeatherCard = ({ location, temperature, condition, humidity, windSpeed, forecast }) => {
  return (
    <div className="enhanced-weather-card">
      <div className="weather-main">
        <div className="weather-location-info">
          <p className="location-name">{location}</p>
          <div className="weather-stats-inline">
            <span>💧 {humidity}%</span>
            <span>💨 {windSpeed} km/h</span>
          </div>
        </div>
        <div className="weather-temp-main">
          <h2 className="temp-large">{temperature}°C</h2>
          <p className="weather-condition">{condition}</p>
        </div>
      </div>

      {forecast && forecast.length > 0 && (
        <div className="weather-forecast">
          {forecast.map((day, index) => (
            <div key={index} className="forecast-day">
              <span className="forecast-day-name">{day.day}</span>
              <span className="forecast-icon">{day.icon}</span>
              <span className="forecast-temp">{day.temp}°</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default WeatherCard
