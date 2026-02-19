import 'package:flutter/material.dart';
import '../utils/colors.dart';

class WeatherCard extends StatelessWidget {
  final String location;
  final int temperature;
  final String condition;
  final int humidity;
  final int windSpeed;
  final List<WeatherForecast>? forecast;

  const WeatherCard({
    super.key,
    required this.location,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$humidity%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '💧',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$windSpeed km/h',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '💨',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$temperature',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const Text(
                        '°C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    condition,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (forecast != null && forecast!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: forecast!.map((day) => _buildForecastDay(day)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastDay(WeatherForecast day) {
    return Column(
      children: [
        Text(
          day.day,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          '${day.temp}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class WeatherForecast {
  final String day;
  final String icon;
  final int temp;

  WeatherForecast({
    required this.day,
    required this.icon,
    required this.temp,
  });
}
