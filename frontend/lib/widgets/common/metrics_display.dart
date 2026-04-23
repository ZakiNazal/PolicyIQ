import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MetricsDisplay extends StatelessWidget {
  final int cycle;
  final int citizens;
  final int anomalies;
  final DateTime time;

  const MetricsDisplay({
    super.key,
    required this.cycle,
    required this.citizens,
    required this.anomalies,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMetric('CYCLE', cycle.toString(), AppTheme.accentCyan),
              const SizedBox(width: 20),
              _buildMetric('CITIZENS', citizens.toString(), AppTheme.accentGreen),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetric('ANOMALIES', anomalies.toString(), AppTheme.accentRed),
              const SizedBox(width: 20),
              _buildMetric('TIME', _formatDate(time), AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
