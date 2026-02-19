import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AlertCard extends StatelessWidget {
  final String type;
  final String title;
  final String message;
  final String time;

  const AlertCard({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
  });

  Color get _backgroundColor {
    switch (type) {
      case 'warning':
        return const Color(0xFFFFF3CD);
      case 'error':
        return const Color(0xFFFEE2E2);
      case 'success':
        return const Color(0xFFD1FAE5);
      default:
        return const Color(0xFFDEEBFF);
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'warning':
        return AppTheme.warningOrange;
      case 'error':
        return AppTheme.errorRed;
      case 'success':
        return AppTheme.successGreen;
      default:
        return AppTheme.infoBlue;
    }
  }

  IconData get _icon {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon,
            color: _iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
