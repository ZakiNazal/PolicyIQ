import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Knob Model ──────────────────────────────────────────────────────────────
class SimKnob {
  final String id;
  final String label;
  final String description;
  final double min;
  final double max;
  double value;
  final Color accentColor;
  final String unit;

  SimKnob({
    required this.id,
    required this.label,
    required this.description,
    required this.min,
    required this.max,
    required this.value,
    required this.accentColor,
    this.unit = '%',
  });
}

final List<SimKnob> defaultKnobs = [
  SimKnob(
    id: 'tax_rate',
    label: 'Tax Policy',
    description: 'Malaysian income & corporate tax rates',
    min: 0, max: 100, value: 35,
    accentColor: AppTheme.accentCyan,
    unit: '%',
  ),
  SimKnob(
    id: 'welfare',
    label: 'Social Welfare',
    description: 'BRIM, aid programs & social safety nets',
    min: 0, max: 100, value: 60,
    accentColor: AppTheme.accentGreen,
    unit: 'pts',
  ),
  SimKnob(
    id: 'surveillance',
    label: 'Digital Surveillance',
    description: 'Data collection & monitoring systems',
    min: 0, max: 100, value: 25,
    accentColor: AppTheme.accentRed,
    unit: '%',
  ),
  SimKnob(
    id: 'media_control',
    label: 'Media Regulation',
    description: 'Information flow & content control',
    min: 0, max: 100, value: 40,
    accentColor: AppTheme.accentAmber,
    unit: '%',
  ),
  SimKnob(
    id: 'innovation',
    label: 'Digital Economy',
    description: 'Technology adoption & digital transformation',
    min: 0, max: 100, value: 70,
    accentColor: AppTheme.accentPurple,
    unit: 'x',
  ),
  SimKnob(
    id: 'migration',
    label: 'Labor Migration',
    description: 'Foreign worker policies & migration flow',
    min: -100, max: 100, value: 15,
    accentColor: AppTheme.accentBlue,
    unit: 'k/yr',
  ),
  SimKnob(
    id: 'resource_scarcity',
    label: 'Resource Management',
    description: 'Energy, water & resource allocation',
    min: 0, max: 100, value: 30,
    accentColor: AppTheme.accentRed,
    unit: '%',
  ),
  SimKnob(
    id: 'trust_index',
    label: 'Public Trust',
    description: 'Confidence in government institutions',
    min: 0, max: 100, value: 55,
    accentColor: AppTheme.accentCyan,
    unit: 'pts',
  ),
];

// ── Citizen Model ─────────────────────────────────────────────────────────
class Citizen {
  final String id;
  final String name;
  final String archetype;
  final int age;
  final String district;
  final double wealthScore;
  final double loyaltyScore;
  final double stressLevel;
  final String anomalyFlag;
  final Color flagColor;
  final Map<String, dynamic> jsonOutput;
  final List<String> internalMonologue;

  const Citizen({
    required this.id,
    required this.name,
    required this.archetype,
    required this.age,
    required this.district,
    required this.wealthScore,
    required this.loyaltyScore,
    required this.stressLevel,
    required this.anomalyFlag,
    required this.flagColor,
    required this.jsonOutput,
    required this.internalMonologue,
  });
}

final List<Citizen> mockCitizens = [
  const Citizen(
    id: 'MY-0047',
    name: 'Ahmad Razak',
    archetype: 'DISSENTER',
    age: 34,
    district: 'Klang Valley',
    wealthScore: 0.12,
    loyaltyScore: 0.08,
    stressLevel: 0.91,
    anomalyFlag: 'CRITICAL',
    flagColor: AppTheme.accentRed,
    internalMonologue: [
      'BRIM payments delayed again this month...',
      'The news says economy is improving. I don\'t see it.',
      'My neighbor from Selangor disappeared after the policy change.',
      'Need to be careful. Digital monitoring everywhere.',
    ],
    jsonOutput: {
      'citizen_id': 'MY-0047',
      'demographic': 'B40-Malay-Urban',
      'behavior_vector': [0.91, 0.08, 0.77, 0.03],
      'threat_score': 0.87,
      'predicted_action': 'PROTEST',
      'network_connections': 14,
      'flagged_keywords': ['BRIM', 'policy change', 'monitoring'],
      'loyalty_decay_rate': -0.023,
      'intervention_recommended': true,
    },
  ),
  const Citizen(
    id: 'MY-1203',
    name: 'Mei Ling',
    archetype: 'CONFORMIST',
    age: 28,
    district: 'Penang',
    wealthScore: 0.61,
    loyaltyScore: 0.84,
    stressLevel: 0.22,
    anomalyFlag: 'STABLE',
    flagColor: AppTheme.accentGreen,
    internalMonologue: [
      'Digital economy initiatives are working well.',
      'My e-wallet balance increased after the new program.',
      'Neighbor spreading misinformation online. Reported it.',
      'Grateful for Malaysia\'s stability and progress.',
    ],
    jsonOutput: {
      'citizen_id': 'MY-1203',
      'demographic': 'M40-Chinese-Urban',
      'behavior_vector': [0.22, 0.84, 0.18, 0.91],
      'threat_score': 0.03,
      'predicted_action': 'COMPLY',
      'network_connections': 6,
      'flagged_keywords': [],
      'loyalty_decay_rate': 0.004,
      'intervention_recommended': false,
    },
  ),
  const Citizen(
    id: 'MY-0891',
    name: 'Raj Kumar',
    archetype: 'OPPORTUNIST',
    age: 45,
    district: 'Johor',
    wealthScore: 0.78,
    loyaltyScore: 0.45,
    stressLevel: 0.38,
    anomalyFlag: 'WATCH',
    flagColor: AppTheme.accentAmber,
    internalMonologue: [
      'Foreign worker quotas changed again. Opportunity.',
      'Official permits are slow. Alternative channels available.',
      'If the audit comes before month end, I\'m exposed.',
      'Need to move some funds to the digital wallet.',
    ],
    jsonOutput: {
      'citizen_id': 'MY-0891',
      'demographic': 'T20-Indian-SemiUrban',
      'behavior_vector': [0.38, 0.45, 0.62, 0.55],
      'threat_score': 0.44,
      'predicted_action': 'EXPLOIT_LOOPHOLE',
      'network_connections': 31,
      'flagged_keywords': ['foreign worker', 'permits', 'audit'],
      'loyalty_decay_rate': -0.007,
      'intervention_recommended': false,
    },
  ),
];

// ── Sentiment Heatmap Data ───────────────────────────────────────────────
class HeatCell {
  final String district;
  final String metric;
  final double value;

  const HeatCell({
    required this.district,
    required this.metric,
    required this.value,
  });
}

final List<String> districts = ['Klang Valley', 'Penang', 'Johor', 'Sabah', 'Sarawak', 'Kelantan', 'Perlis'];
final List<String> sentimentMetrics = ['Loyalty', 'Unrest', 'Productivity', 'Compliance', 'Wellbeing'];

final Map<String, Map<String, double>> heatmapData = {
  'Klang Valley': {'Loyalty': 0.82, 'Unrest': 0.12, 'Productivity': 0.91, 'Compliance': 0.88, 'Wellbeing': 0.76},
  'Penang': {'Loyalty': 0.84, 'Unrest': 0.08, 'Productivity': 0.87, 'Compliance': 0.92, 'Wellbeing': 0.80},
  'Johor': {'Loyalty': 0.55, 'Unrest': 0.44, 'Productivity': 0.61, 'Compliance': 0.58, 'Wellbeing': 0.42},
  'Sabah': {'Loyalty': 0.63, 'Unrest': 0.32, 'Productivity': 0.78, 'Compliance': 0.66, 'Wellbeing': 0.61},
  'Sarawak': {'Loyalty': 0.39, 'Unrest': 0.67, 'Productivity': 0.44, 'Compliance': 0.41, 'Wellbeing': 0.28},
  'Kelantan': {'Loyalty': 0.71, 'Unrest': 0.22, 'Productivity': 0.69, 'Compliance': 0.74, 'Wellbeing': 0.65},
  'Perlis': {'Loyalty': 0.18, 'Unrest': 0.91, 'Productivity': 0.35, 'Compliance': 0.22, 'Wellbeing': 0.14},
};

// ── Sankey Flow Data ─────────────────────────────────────────────────────
class SankeyFlow {
  final String from;
  final String to;
  double value;
  final Color color;

  SankeyFlow({
    required this.from,
    required this.to,
    required this.value,
    required this.color,
  });
}

final List<SankeyFlow> behaviorFlows = [
  SankeyFlow(from: 'Compliant', to: 'Productive', value: 0.72, color: AppTheme.accentGreen),
  SankeyFlow(from: 'Compliant', to: 'Apathetic', value: 0.18, color: AppTheme.accentBlue),
  SankeyFlow(from: 'Stressed', to: 'Apathetic', value: 0.41, color: AppTheme.accentAmber),
  SankeyFlow(from: 'Stressed', to: 'Resistant', value: 0.38, color: AppTheme.accentRed),
  SankeyFlow(from: 'Resistant', to: 'Organized', value: 0.15, color: AppTheme.accentRed),
  SankeyFlow(from: 'Apathetic', to: 'Withdrawn', value: 0.29, color: AppTheme.textMuted),
];
