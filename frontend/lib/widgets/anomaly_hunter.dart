/// anomaly_hunter.dart — Spotlights individual citizen anomalies.
///
/// Displays breaking-point and loophole-exploitation flags from Contract E
/// with agent ID, demographic, and reason.

import 'package:flutter/material.dart';
import '../models/contracts.dart';

class AnomalyHunter extends StatelessWidget {
  final List<Anomaly> anomalies;

  const AnomalyHunter({super.key, required this.anomalies});

  @override
  Widget build(BuildContext context) {
    if (anomalies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD93D), size: 18),
          const SizedBox(width: 8),
          Text('Anomaly Hunter (${anomalies.length} flagged)',
              style: const TextStyle(
                  color: Color(0xFFFFD93D),
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        ...anomalies.map((a) => _AnomalyCard(anomaly: a)),
      ],
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  final Anomaly anomaly;
  const _AnomalyCard({required this.anomaly});

  Color get _typeColor {
    switch (anomaly.type) {
      case 'breaking_point':
        return const Color(0xFFFF6B6B);
      case 'loophole':
        return const Color(0xFFFFD93D);
      default:
        return const Color(0xFFFF9F43);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _typeColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _typeColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(anomaly.agentId,
                style: TextStyle(
                    color: _typeColor, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${anomaly.demographic} — ${anomaly.type.replaceAll('_', ' ')}',
                    style: TextStyle(color: _typeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(anomaly.reason,
                    style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
