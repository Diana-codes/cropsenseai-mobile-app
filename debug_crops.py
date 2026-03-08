#!/usr/bin/env python3
"""Debug script to check why crops aren't being found"""

from services import RwandaCropPlanner, WeatherService

# Initialize services
planner = RwandaCropPlanner()
weather_service = WeatherService()

# Test parameters
province = "Eastern Province"
district = "Bugesera"
land_type = "Wetland"
season = "Season A (Sept - Jan)"

# Get weather
weather = weather_service.get_weather_data("Rwanda", province, district)

print("=" * 60)
print("DEBUG: Crop Recommendation Search")
print("=" * 60)
print(f"Province: {province}")
print(f"District: {district}")
print(f"Land Type: {land_type}")
print(f"Season: {season}")
print(f"Weather: {weather.get('temperature')}°C, {weather.get('humidity')}% humidity")
print()

# Check zone mapping
from services import RwandaCropPlanner
zone = RwandaCropPlanner().landtype_to_zone.get(land_type.lower(), "")
print(f"Mapped Zone: '{zone}'")
print()

# Check season months
months = RwandaCropPlanner()._season_to_months(season)
print(f"Season Months: {months}")
print()

# Get recommendations
recs = planner.get_recommendations(
    province=province,
    district=district,
    land_type=land_type,
    season=season,
    weather_data=weather
)

print(f"Found {len(recs)} recommendations")
print()

if recs:
    print("Recommendations:")
    for i, rec in enumerate(recs[:5], 1):
        print(f"{i}. {rec.crop} (Zone: {rec.agro_zone}, Window: {rec.sowing_window})")
else:
    print("❌ No crops found!")
    print()
    print("Checking CSV data...")
    print(f"Total rows in CSV: {len(planner._rows)}")
    print()
    
    # Check zones in CSV
    zones_in_csv = set()
    for row in planner._rows[:20]:  # Check first 20 rows
        zone_val = (row.get("AgroEcological Zone") or "").strip()
        if zone_val:
            zones_in_csv.add(zone_val)
    print(f"Zones in CSV (sample): {sorted(list(zones_in_csv))[:10]}")
    print()
    
    # Check if any crops match the zone
    matching_zone = [r for r in planner._rows if (r.get("AgroEcological Zone") or "").strip() == zone]
    print(f"Crops with zone '{zone}': {len(matching_zone)}")
    if matching_zone:
        print("Sample crops:")
        for r in matching_zone[:5]:
            crop = r.get("Crop", "").strip()
            early = r.get("Early Sowing Month", "").strip()
            late = r.get("Later Sowing Month", "").strip()
            print(f"  - {crop}: Months {early}-{late}")

print("=" * 60)
