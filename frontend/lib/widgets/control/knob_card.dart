import 'package:flutter/material.dart';
import '../../models/sim_models.dart';
import '../../theme/app_theme.dart';

class KnobCard extends StatelessWidget {
  final SimKnob knob;
  final bool isActive;
  final bool overrideActive;
  final Function(double) onChanged;

  const KnobCard({
    super.key,
    required this.knob,
    required this.isActive,
    required this.overrideActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderColor: isActive ? knob.accentColor : null,
      glowColor: isActive ? knob.accentColor : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: knob.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  knob.label.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? knob.accentColor : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              Text(
                '${knob.value.round()}${knob.unit}',
                style: TextStyle(
                  color: isActive ? knob.accentColor : AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            knob.description,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Slider track
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              thumbColor: knob.accentColor,
              activeTrackColor: knob.accentColor,
              inactiveTrackColor: AppTheme.border,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              overlayColor: knob.accentColor.withOpacity(0.1),
            ),
            child: Slider(
              value: knob.value,
              min: knob.min,
              max: knob.max,
              onChanged: overrideActive ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
