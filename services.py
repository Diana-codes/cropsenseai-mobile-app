import csv
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Dict, List, Optional
from zoneinfo import ZoneInfo

import requests

_GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search"
_OPENWEATHER_WEATHER_URL = "https://api.openweathermap.org/data/2.5/weather"


def _openweather_id_to_wmo_like(ow_id: int) -> int:
    """Map OpenWeather condition IDs to WMO-like codes used by the mobile UI."""
    if ow_id == 800:
        return 0
    if 801 <= ow_id <= 804:
        return 2
    if 200 <= ow_id < 300:
        return 95
    if 300 <= ow_id < 400:
        return 51
    if 500 <= ow_id < 600:
        return 61
    if 600 <= ow_id < 700:
        return 71
    if 700 <= ow_id < 800:
        return 45
    return 3


class WeatherService:
    """Service to fetch weather data for Rwanda locations"""
    
    def __init__(self):
        # Using Open-Meteo API (free, no API key required)
        self.base_url = "https://api.open-meteo.com/v1/forecast"
        # Default Rwanda coordinates (Kigali)
        self.rwanda_coords = {"latitude": -1.9536, "longitude": 29.8739}
    
        # Approximate coordinates for major Rwanda locations
        # These are rough approximations - in production, use a geocoding service
        self.location_coords = {
            # Provinces (centroid coordinates)
            "kigali city": {"latitude": -1.9536, "longitude": 29.8739},
            "eastern province": {"latitude": -1.9441, "longitude": 30.4358},
            "northern province": {"latitude": -1.5842, "longitude": 29.6333},
            "southern province": {"latitude": -2.4778, "longitude": 29.7389},
            "western province": {"latitude": -2.0303, "longitude": 29.3259},
            
            # Major districts (sample - can be expanded)
            "gasabo": {"latitude": -1.9441, "longitude": 30.0611},
            "bugesera": {"latitude": -2.1833, "longitude": 30.1500},
            "musanze": {"latitude": -1.5000, "longitude": 29.6167},
            "huye": {"latitude": -2.4667, "longitude": 29.7500},
            "rubavu": {"latitude": -1.6833, "longitude": 29.3167},
            # Eastern Province — was missing; province centroid is coarse
            "rwamagana": {"latitude": -1.9487, "longitude": 30.4347},
            # Kigali City districts (distinct from each other / from Eastern Province)
            "kicukiro": {"latitude": -2.0014, "longitude": 30.1002},
            "nyarugenge": {"latitude": -1.9536, "longitude": 29.8739},
        }

    def _geocode_rwanda(self, query: str) -> Optional[Dict[str, float]]:
        """Resolve a place name inside Rwanda using Open-Meteo geocoding (free, no API key)."""
        q = (query or "").strip()
        if not q:
            return None
        try:
            r = requests.get(
                _GEOCODE_URL,
                params={"name": q, "count": 8, "language": "en"},
                timeout=10,
            )
            r.raise_for_status()
            payload = r.json()
            for res in payload.get("results") or []:
                cc = (res.get("country_code") or "").upper()
                country = (res.get("country") or "").lower()
                if cc == "RW" or "rwanda" in country:
                    return {
                        "latitude": float(res["latitude"]),
                        "longitude": float(res["longitude"]),
                    }
        except Exception as e:
            print(f"Geocoding failed for {q!r}: {e}")
        return None

    def _get_coordinates(self, province: str = "", district: str = "") -> Dict[str, float]:
        """Get coordinates for a location, falling back to defaults"""
        # Try district first (more specific)
        if district:
            district_key = district.lower().strip()
            if district_key in self.location_coords:
                return self.location_coords[district_key]
            geo = self._geocode_rwanda(district)
            if geo:
                return geo

        # Try province name / centroid table
        if province:
            province_key = province.lower().strip()
            if province_key in self.location_coords:
                return self.location_coords[province_key]
            geo = self._geocode_rwanda(province)
            if geo:
                return geo

        # Fallback to default Rwanda coordinates (Kigali area)
        return self.rwanda_coords

    def _fetch_openweather(
        self,
        coords: Dict[str, float],
        display_location: str,
        api_key: str,
    ) -> Dict:
        """Current weather from OpenWeather (set OPENWEATHER_API_KEY on the server)."""
        r = requests.get(
            _OPENWEATHER_WEATHER_URL,
            params={
                "lat": coords["latitude"],
                "lon": coords["longitude"],
                "appid": api_key,
                "units": "metric",
            },
            timeout=15,
        )
        r.raise_for_status()
        data = r.json()
        main = data.get("main") or {}
        wind = data.get("wind") or {}
        w0 = (data.get("weather") or [{}])[0]
        ow_id = int(w0.get("id") or 0)
        dt_unix = data.get("dt")
        rain = data.get("rain") or {}
        precip = float(rain.get("1h") or rain.get("3h") or 0)

        ts_display: str = "N/A"
        if dt_unix is not None:
            try:
                tz_kigali = ZoneInfo("Africa/Kigali")
                ts_display = datetime.fromtimestamp(
                    int(dt_unix), tz=timezone.utc
                ).astimezone(tz_kigali).isoformat()
            except Exception:
                ts_display = str(dt_unix)

        return {
            "location": display_location,
            "temperature": main.get("temp") if main.get("temp") is not None else "N/A",
            "humidity": main.get("humidity") if main.get("humidity") is not None else "N/A",
            "wind_speed": wind.get("speed", "N/A"),
            "precipitation": precip,
            "weather_code": _openweather_id_to_wmo_like(ow_id),
            "timestamp": ts_display,
            "coordinates": coords,
            "weather_provider": "openweather",
            "weather_description": (w0.get("description") or "").strip(),
        }

    def get_weather_data(self, location: str = "Rwanda", province: str = "", district: str = "") -> Dict:
        """Fetch current weather data for a specific location in Rwanda"""
        coords = self._get_coordinates(province, district)
        display_location = (
            location
            or (f"{district}, {province}" if district and province else province or "Rwanda")
        )

        api_key = (
            os.environ.get("OPENWEATHER_API_KEY")
            or os.environ.get("CROPSENSE_OPENWEATHER_API_KEY")
            or ""
        ).strip()
        if api_key:
            try:
                return self._fetch_openweather(coords, display_location, api_key)
            except Exception as e:
                print(f"OpenWeather failed, falling back to Open-Meteo: {e}")

        try:
            params = {
                "latitude": coords["latitude"],
                "longitude": coords["longitude"],
                "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation",
                "timezone": "Africa/Kigali",
            }
            for attempt in range(2):
                try:
                    response = requests.get(self.base_url, params=params, timeout=15)
                    response.raise_for_status()
                    break
                except Exception as retry_err:
                    if attempt == 1:
                        raise retry_err
            data = response.json()

            current_weather = data.get("current", {})

            temp = current_weather.get("temperature_2m")
            humidity = current_weather.get("relative_humidity_2m")

            return {
                "location": display_location,
                "temperature": temp if temp is not None else "N/A",
                "humidity": humidity if humidity is not None else "N/A",
                "wind_speed": current_weather.get("wind_speed_10m", "N/A"),
                "precipitation": current_weather.get("precipitation", 0),
                "weather_code": current_weather.get("weather_code", "N/A"),
                "timestamp": current_weather.get("time", "N/A"),
                "coordinates": coords,
                "weather_provider": "open-meteo",
            }
        except Exception as e:
            print(f"Error fetching weather data for {location}: {e}")
            return {
                "location": location or "Rwanda",
                "temperature": "N/A",
                "humidity": "N/A",
                "wind_speed": "N/A",
                "precipitation": 0,
                "weather_code": "N/A",
                "timestamp": "N/A",
                "error": str(e),
            }


class RwandaAgronomistAdvisor:
    """Service to provide agronomic advice based on crop type and weather conditions"""
    
    def __init__(self):
        self.crop_advice = {
            "maize": {
                "sunny": "Maize thrives in sunny conditions. Ensure adequate irrigation during dry spells.",
                "rainy": "Good growing conditions. Monitor for fungal diseases in humid weather.",
                "cloudy": "Provide supplemental nutrients. Maize may grow slower in low light.",
                "cold": "Maize prefers warm conditions (>15°C). Consider frost protection."
            },
            "beans": {
                "sunny": "Beans do well in sunny conditions. Ensure consistent moisture.",
                "rainy": "Monitor for root rot. Improve drainage to prevent waterlogging.",
                "cloudy": "Beans can tolerate shade. Ensure good air circulation.",
                "cold": "Keep beans warm. They prefer temperatures between 15-25°C."
            },
            "cassava": {
                "sunny": "Cassava is drought-tolerant. Minimal irrigation needed.",
                "rainy": "Cassava tolerates excess moisture well. Good for rainy seasons.",
                "cloudy": "Cassava can grow in partial shade. Growth may be slower.",
                "cold": "Cassava is cold-sensitive. Protect from frost."
            },
            "rice": {
                "sunny": "Rice needs consistent moisture. Ensure standing water in paddies.",
                "rainy": "Ideal growing season. Maintain proper water levels.",
                "cloudy": "Rice can tolerate shade. Monitor fungal diseases.",
                "cold": "Rice prefers warm conditions. Avoid planting in cold periods."
            },
            "banana": {
                "sunny": "Bananas need shade and moisture. Plant in semi-shade if possible.",
                "rainy": "Excellent growing conditions. Ensure good drainage.",
                "cloudy": "Bananas prefer partial shade. Maintain consistent moisture.",
                "cold": "Bananas are sensitive to cold. Protect from temperature drops."
            },
            "tomato": {
                "sunny": "Tomatoes love sunlight. Ensure at least 6-8 hours daily.",
                "rainy": "Monitor for fungal diseases. Improve air circulation.",
                "cloudy": "Tomatoes may produce less fruit. Supplement with nutrients.",
                "cold": "Tomatoes are frost-sensitive. Protect young plants."
            },
            "potato": {
                "sunny": "Potatoes do well in sunny conditions. Ensure adequate moisture.",
                "rainy": "Monitor for late blight in humid conditions.",
                "cloudy": "Potatoes can tolerate some shade. Ensure good drainage.",
                "cold": "Cold conditions are ideal for potato growth in some regions."
            },
            "wheat": {
                "sunny": "Wheat needs sunlight. Ensure 6+ hours of direct sun.",
                "rainy": "Monitor for fungal diseases. Ensure good drainage.",
                "cloudy": "Wheat growth may slow. Increase nutrient supplementation.",
                "cold": "Winter wheat thrives in cool conditions."
            },
            # Disease classes from your MobileNetV2 model
            "healthy": {
                "sunny": "Leaf appears healthy. Maintain good field hygiene and regular scouting to detect issues early.",
                "rainy": "Leaf appears healthy. Continue monitoring for early signs of fungal disease during humid periods.",
                "cloudy": "Leaf appears healthy. Avoid overwatering and keep nutrients balanced.",
                "cold": "Leaf appears healthy. Protect young plants from extreme cold and water stress."
            },
            "powdery": {
                "sunny": "Powdery mildew detected. Remove heavily infected leaves and avoid overhead irrigation during the evening.",
                "rainy": "Powdery mildew detected. High humidity favors this disease; improve air circulation and follow local fungicide recommendations.",
                "cloudy": "Powdery mildew detected. Monitor the whole field, thin dense canopy, and apply recommended fungicide if infection spreads.",
                "cold": "Powdery mildew detected. Cool, humid conditions can slow plant growth; maintain balanced nutrition and follow local control guidelines."
            },
            "rust": {
                "sunny": "Rust symptoms detected. Remove and destroy severely affected leaves to reduce spore spread.",
                "rainy": "Rust symptoms detected. Humid conditions favor rust; avoid water staying long on leaves and follow local fungicide schedules.",
                "cloudy": "Rust symptoms detected. Monitor nearby plants for new spots and consider resistant varieties in future seasons.",
                "cold": "Rust symptoms detected. Maintain crop vigor with good fertilizer management and remove volunteer host plants."
            },
        }
    
    def get_weather_condition(self, temperature: float, humidity: float) -> str:
        """Determine weather condition based on temperature and humidity"""
        if temperature < 15:
            return "cold"
        elif humidity > 70:
            return "rainy"
        elif humidity < 40:
            return "sunny"
        else:
            return "cloudy"
    
    def get_advice(self, crop: str, temperature: float = 20, humidity: float = 60) -> Dict:
        """Get agronomic advice based on crop and weather conditions"""
        crop_lower = crop.lower().strip()
        # CSV uses "Corn", "Bean" etc. - map to advisor keys
        crop_aliases = {"corn": "maize", "bean": "beans", "beans, harvested green": "beans"}
        crop_lower = crop_aliases.get(crop_lower, crop_lower)
        
        weather_condition = self.get_weather_condition(temperature, humidity)
        
        if crop_lower in self.crop_advice:
            advice_text = self.crop_advice[crop_lower].get(
                weather_condition,
                f"General advice: {crop} requires proper care and monitoring."
            )
        else:
            advice_text = f"Crop '{crop}' not found in our database. Please contact an agronomist for specific advice."
        
        return {
            "crop": crop,
            "weather_condition": weather_condition,
            "temperature": temperature,
            "humidity": humidity,
            "advice": advice_text,
            "additional_tips": self._get_general_tips(crop_lower)
        }
    
    def _get_general_tips(self, crop: str) -> List[str]:
        """Get general farming tips for a crop"""
        general_tips = {
            "maize": [
                "Plant after first rains",
                "Space plants 25cm apart",
                "Apply organic manure before planting",
                "Monitor for pests and diseases"
            ],
            "beans": [
                "Choose well-drained soil",
                "Plant in rows 30cm apart",
                "Harvest when pods are dry",
                "Practice crop rotation"
            ],
            "cassava": [
                "Plant in well-drained soil",
                "Harvest after 12-18 months",
                "Use healthy stems for propagation",
                "Control weeds in first 3 months"
            ],
            "rice": [
                "Maintain water level in paddies",
                "Apply fertilizer in splits",
                "Monitor for stem borers",
                "Harvest when grains are mature"
            ],
            "banana": [
                "Plant in fertile, well-drained soil",
                "Space plants 3-4m apart",
                "Mulch around plants",
                "Remove dead leaves regularly"
            ],
            "tomato": [
                "Use quality seeds",
                "Support plants with stakes",
                "Water consistently",
                "Prune for better fruit quality"
            ],
            "potato": [
                "Use certified seed potatoes",
                "Plant in ridges for better drainage",
                "Hill soil around plants as they grow",
                "Harvest 3-4 months after planting"
            ],
            "wheat": [
                "Plant in cool season",
                "Ensure good seed-soil contact",
                "Apply balanced fertilizer",
                "Harvest when grains are hard"
            ],
            "healthy": [
                "Continue regular field scouting at least once per week",
                "Keep the field weed-free to reduce pest and disease pressure",
                "Use clean planting material and certified seed",
                "Maintain soil fertility with organic matter and balanced fertilizer"
            ],
            "powdery": [
                "Remove and burn or bury heavily infected plant residues after harvest",
                "Avoid very dense planting that reduces air movement",
                "Use disease-free seed or planting material",
                "Rotate with non-host crops to break the disease cycle"
            ],
            "rust": [
                "Plant recommended resistant or tolerant varieties when available",
                "Remove volunteer host plants around the field",
                "Do not over-apply nitrogen fertilizer, which can favor rust",
                "Consult local extension services for recommended fungicide use"
            ],
        }
        
        return general_tips.get(crop, ["Consult local agricultural extension for specific tips"])


@dataclass
class CropRecommendation:
    crop: str
    agro_zone: str
    reason: str
    sowing_window: str
    growing_period: str


class RwandaCropPlanner:
    """
    Simple planner that reads Rwanda_Crop_calendar_Data.csv and recommends crops
    based on agro-ecological zone (approximated from land type) and season.
    """

    def __init__(self, csv_path: str = "Rwanda_Crop_calendar_Data.csv"):
        self._rows: List[Dict] = []
        try:
            with open(csv_path, newline="", encoding="utf-8") as f:
                reader = csv.reader(f)
                header = next(reader)
                next(reader)  # Skip sub-header (Day, Month, etc.)
                # CSV cols: 0=Crop, 1=AgroEcological Zone, 4=Early Sowing Month, 6=Later Sowing Month
                # 10=Growing period Value, 17=AgroEcological Zone Practices
                for row in reader:
                    if len(row) < 18:
                        continue
                    try:
                        early_month = int(row[4].strip()) if row[4].strip() else 0
                    except (ValueError, IndexError):
                        early_month = 0
                    try:
                        late_month = int(row[6].strip()) if row[6].strip() else 0
                    except (ValueError, IndexError):
                        late_month = 0
                    self._rows.append({
                        "Crop": (row[0] or "").strip(),
                        "AgroEcological Zone": (row[1] or "").strip(),
                        "early_month": early_month,
                        "late_month": late_month,
                        "reason": (row[17] or "").strip() if len(row) > 17 else "",
                        "growing_period": (row[10] or "").strip() if len(row) > 10 else "",
                    })
            print(f"✓ Loaded crop calendar data from {csv_path} ({len(self._rows)} rows)")
        except Exception as e:
            print(f"✗ Error loading crop calendar data from {csv_path}: {e}")
            self._rows = []

        # Map land type to agro-ecological zones (each land type can match multiple zones)
        self.landtype_to_zones: Dict[str, List[str]] = {
            "wetland": ["Imbo", "Impara & Kivu lake borders"],
            "valley": ["Imbo", "Impara & Kivu lake borders"],
            "hillside": ["Congo-Nile Watershed Divide & Buberuka highlands", "Impara & Kivu lake borders"],
            "plateau": ["Birunga", "Central Plateau", "Eastern Plateau & Eastern Savanna"],
        }

    def _season_to_months(self, season: str) -> List[int]:
        """Map high-level season string to a list of sowing months."""
        season = season.lower()
        if "season-a" in season or "season a" in season:
            # Sept–Jan
            return [9, 10, 11, 12, 1]
        if "season-b" in season or "season b" in season:
            # Feb–June
            return [2, 3, 4, 5, 6]
        # Fallback: all months
        return list(range(1, 13))

    def get_recommendations(
        self,
        province: str,
        district: str,
        land_type: str,
        season: str,
        weather_data: Optional[Dict] = None,
    ) -> List[CropRecommendation]:
        if not self._rows:
            return []

        months = self._season_to_months(season)
        zones = self.landtype_to_zones.get(land_type.lower().strip(), [])

        recs: List[CropRecommendation] = []
        
        # Extract weather info for ranking
        temp = None
        humidity = None
        if weather_data:
            try:
                temp = float(weather_data.get("temperature", 0)) if weather_data.get("temperature") != "N/A" else None
                humidity = float(weather_data.get("humidity", 0)) if weather_data.get("humidity") != "N/A" else None
            except (ValueError, TypeError):
                pass

        for row in self._rows:
            agro = row.get("AgroEcological Zone") or ""
            if zones and agro not in zones:
                continue

            early_month = row.get("early_month", 0)
            late_month = row.get("late_month", 0)

            # If sowing window overlaps with desired season months
            if early_month in months or late_month in months:
                crop_name = row.get("Crop") or ""
                reason = row.get("reason") or ""
                sowing_window = f"{early_month}-{late_month}" if early_month and late_month else "N/A"
                growing_period = row.get("growing_period") or ""

                recs.append(
                    CropRecommendation(
                        crop=crop_name,
                        agro_zone=agro,
                        reason=reason,
                        sowing_window=sowing_window,
                        growing_period=growing_period,
                    )
                )

        # Rank crops based on weather suitability if weather data is available
        if temp is not None and humidity is not None:
            # CSV uses "Corn", "Bean", "Pea, dry" etc. - normalize for scoring
            _CROP_ALIASES = {
                "corn": "maize", "bean": "beans", "beans, harvested green": "beans",
                "pea, dry": "peas", "pea": "peas", "beet, sugar": "beet", "beet": "beet",
            }

            def weather_score(rec: CropRecommendation) -> float:
                """Score crops based on weather suitability"""
                crop_lower = rec.crop.lower().strip()
                crop_for_scoring = _CROP_ALIASES.get(crop_lower, crop_lower)
                score = 0.0
                
                # Temperature-based scoring
                if "rice" in crop_for_scoring or "banana" in crop_for_scoring:
                    # Prefer warmer (20-30°C)
                    if 20 <= temp <= 30:
                        score += 2.0
                    elif 15 <= temp < 20 or 30 < temp <= 35:
                        score += 1.0
                elif "potato" in crop_for_scoring or "wheat" in crop_for_scoring:
                    # Prefer cooler (15-25°C)
                    if 15 <= temp <= 25:
                        score += 2.0
                    elif 10 <= temp < 15 or 25 < temp <= 30:
                        score += 1.0
                elif "maize" in crop_for_scoring or "beans" in crop_for_scoring or "cassava" in crop_for_scoring or "peas" in crop_for_scoring or "sorghum" in crop_for_scoring:
                    # Prefer moderate (18-28°C)
                    if 18 <= temp <= 28:
                        score += 2.0
                    elif 15 <= temp < 18 or 28 < temp <= 32:
                        score += 1.0
                
                # Humidity-based scoring
                if "rice" in crop_for_scoring:
                    # Rice prefers high humidity
                    if humidity >= 60:
                        score += 1.5
                    elif humidity >= 40:
                        score += 0.5
                elif "cassava" in crop_for_scoring:
                    # Cassava is drought-tolerant, moderate humidity is fine
                    if 40 <= humidity <= 70:
                        score += 1.0
                elif "maize" in crop_for_scoring or "beans" in crop_for_scoring:
                    # Prefer moderate humidity (50-70%)
                    if 50 <= humidity <= 70:
                        score += 1.0
                    elif 40 <= humidity < 50 or 70 < humidity <= 80:
                        score += 0.5
                
                return score
            
            # Sort by weather score (descending), then by crop name
            recs.sort(key=lambda r: (-weather_score(r), r.crop))
        else:
            # No weather data - sort by crop name for stability
            recs.sort(key=lambda r: r.crop)
        
        return recs