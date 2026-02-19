import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  final List<Map<String, dynamic>> _processes = [
    {
      'name': 'WET RICE CULTIVATION',
      'description': 'Traditional paddy rice cultivation process in flooded fields',
      'duration': '120-140 days',
      'currentPhase': 'Phase progress',
      'progress': 16,
      'stages': [
        {'name': 'Soil preparation', 'status': 'completed'},
        {'name': 'Clear weeds and crop residue', 'status': 'upcoming'},
      ],
    },
    {
      'name': 'GREENHOUSE TOMATOES',
      'description': 'Tomato care in a controlled greenhouse environment',
      'duration': '80-100 days',
      'currentPhase': 'Pest control',
      'progress': 0,
      'stages': [
        {'name': 'Seed sowing', 'status': 'upcoming'},
      ],
    },
    {
      'name': 'GREENHOUSE VEGETABLES',
      'description': 'Leafy vegetables cultivation in greenhouse environment',
      'duration': '30-60 days',
      'currentPhase': 'Not started',
      'progress': 0,
      'stages': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Process'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _processes.length,
        itemBuilder: (context, index) {
          final process = _processes[index];
          return _buildProcessCard(context, process);
        },
      ),
    );
  }

  Widget _buildProcessCard(BuildContext context, Map<String, dynamic> process) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      process['name'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      process['description'],
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                process['duration'],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            process['currentPhase'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: process['progress'] / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${process['progress']}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((process['stages'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...((process['stages'] as List).map((stage) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      stage['status'] == 'completed'
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16,
                      color: stage['status'] == 'completed'
                          ? AppTheme.successGreen
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stage['name'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            })),
          ],
        ],
      ),
    );
  }
}
