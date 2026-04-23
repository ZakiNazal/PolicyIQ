import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StabilityMeter extends StatelessWidget {
  final double stress;

  const StabilityMeter({super.key, required this.stress});

  @override
  Widget build(BuildContext context) {
    final segments = [
      ('STABLE', AppTheme.accentGreen, 0.0, 0.35),
      ('MODERATE', AppTheme.accentAmber, 0.35, 0.6),
      ('HIGH STRESS', AppTheme.accentRed, 0.6, 1.0),
    ];

    return Column(
      children: segments.map((s) {
        final isActive = stress >= s.$3 && (stress < s.$4 || s.$4 == 1.0);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? s.$2.withOpacity(0.12) : AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? s.$2.withOpacity(0.5) : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              if (isActive)
                DotBadge(color: s.$2)
              else
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.textMuted,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.$1,
                  style: TextStyle(
                    color: isActive ? s.$2 : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
