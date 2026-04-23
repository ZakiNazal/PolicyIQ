import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── The 8 Universal Knobs (Physics Engine) ─────────────────────────────────────
enum UniversalKnobType {
  disposableIncomeDelta,
  operationalExpenseIndex,
  capitalAccessPressure,
  systemicFriction,
  socialEquityWeight,
  systemicTrustBaseline,
  futureMobilityIndex,
  ecologicalResourcePressure,
}

class UniversalKnob {
  final UniversalKnobType type;
  final String label;
  final String description;
  double value; // Range: -1.0 to 1.0
  final Color accentColor;

  UniversalKnob({
    required this.type,
    required this.label,
    required this.description,
    required this.value,
    required this.accentColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'label': label,
      'description': description,
      'value': value,
    };
  }
}

// ── Dynamic Decomposition Sub-Layers ────────────────────────────────────────────
class SubLayer {
  final String id;
  final String name;
  final String description;
  final UniversalKnobType parentKnob;
  final List<String> targetDemographics; // e.g., ["B40", "M40", "Urban"]
  final double impactMultiplier; // Alters parent knob's effect
  final Color accentColor;

  SubLayer({
    required this.id,
    required this.name,
    required this.description,
    required this.parentKnob,
    required this.targetDemographics,
    required this.impactMultiplier,
    required this.accentColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentKnob': parentKnob.name,
      'targetDemographics': targetDemographics,
      'impactMultiplier': impactMultiplier,
    };
  }
}

// ── Agent DNA - Economic Entity (Digital Malaysian) ───────────────────────────────
enum IncomeTier { B40, M40, T20 }

enum OccupationType {
  gigWorker,
  salariedCorporate,
  smeOwner,
  civilServant,
  unemployed,
}

enum LocationMatrix { urban, suburban, rural }

class AgentDNA {
  // Identity Fields
  final String id;
  final String name;
  final IncomeTier incomeTier;
  final OccupationType occupationType;
  final LocationMatrix locationMatrix;

  // Economic Entity Fields (Stream 1 — New)
  final double monthlyIncomeRm;
  final double disposableBufferRm; // Derived
  final double liquidSavingsRm;
  final double debtToIncomeRatio;
  final int dependentsCount;
  final double digitalReadinessScore;
  final Map<String, bool> subsidyFlags;

  // Sensitivity Matrix
  final Map<UniversalKnobType, double> sensitivityWeights; // 0.0 to 1.0

  // Dynamic State (changes during simulation)
  double currentSentiment; // -1.0 to 1.0
  double financialHealth; // 0.0 to 1.0 (0 = breaking point)
  List<String> monologueHistory;
  Map<String, dynamic> currentState;
  String anomalyFlag;

  AgentDNA({
    required this.id,
    required this.name,
    required this.incomeTier,
    required this.occupationType,
    required this.locationMatrix,
    required this.monthlyIncomeRm,
    required this.liquidSavingsRm,
    required this.debtToIncomeRatio,
    required this.dependentsCount,
    required this.digitalReadinessScore,
    required this.subsidyFlags,
    required this.sensitivityWeights,
    this.currentSentiment = 0.0,
    this.financialHealth = 1.0,
    this.monologueHistory = const [],
    this.currentState = const {},
    this.anomalyFlag = 'NORMAL',
  }) : disposableBufferRm = _calculateDisposableBuffer(
          monthlyIncomeRm,
          debtToIncomeRatio,
        );

  static double _calculateDisposableBuffer(double income, double debtRatio) {
    final fixedCosts = income * 0.40;
    final debtPayments = income * debtRatio;
    return income - fixedCosts - debtPayments;
  }

  bool get isAtBreakingPoint => financialHealth <= 0.0 || currentSentiment <= -1.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'incomeTier': incomeTier.name,
      'occupationType': occupationType.name,
      'locationMatrix': locationMatrix.name,
      'monthlyIncomeRm': monthlyIncomeRm,
      'disposableBufferRm': disposableBufferRm,
      'liquidSavingsRm': liquidSavingsRm,
      'debtToIncomeRatio': debtToIncomeRatio,
      'dependentsCount': dependentsCount,
      'digitalReadinessScore': digitalReadinessScore,
      'subsidyFlags': subsidyFlags,
      'sensitivityWeights': sensitivityWeights.map((k, v) => MapEntry(k.name, v)),
      'currentSentiment': currentSentiment,
      'financialHealth': financialHealth,
      'monologueHistory': monologueHistory,
      'currentState': currentState,
      'anomalyFlag': anomalyFlag,
      'isAtBreakingPoint': isAtBreakingPoint,
    };
  }
}

// ── Global State ───────────────────────────────────────────────────────────────
class GlobalState {
  final Map<UniversalKnobType, double> knobValues;
  final List<SubLayer> activeSubLayers;
  final int currentTick;
  final double overallSystemStress;
  final Map<String, dynamic> macroMetrics;

  GlobalState({
    required this.knobValues,
    required this.activeSubLayers,
    this.currentTick = 0,
    this.overallSystemStress = 0.0,
    this.macroMetrics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'knobValues': knobValues.map((k, v) => MapEntry(k.name, v)),
      'activeSubLayers': activeSubLayers.map((sl) => sl.toJson()).toList(),
      'currentTick': currentTick,
      'overallSystemStress': overallSystemStress,
      'macroMetrics': macroMetrics,
    };
  }
}

// ── Agent Decision Response (JSON Payload) ───────────────────────────────────────
class AgentDecision {
  final String agentId;
  final String action; // What the agent decides to do
  final double sentiment; // Updated sentiment (-1.0 to 1.0)
  final double financialChange; // Financial impact
  final String monologue; // Internal monologue
  final Map<String, dynamic> metadata;

  AgentDecision({
    required this.agentId,
    required this.action,
    required this.sentiment,
    required this.financialChange,
    required this.monologue,
    this.metadata = const {},
  });

  factory AgentDecision.fromJson(Map<String, dynamic> json) {
    return AgentDecision(
      agentId: json['agentId'],
      action: json['action'],
      sentiment: (json['sentiment'] as num).toDouble(),
      financialChange: (json['financialChange'] as num).toDouble(),
      monologue: json['monologue'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'action': action,
      'sentiment': sentiment,
      'financialChange': financialChange,
      'monologue': monologue,
      'metadata': metadata,
    };
  }
}

// ── Policy Input & Validation ───────────────────────────────────────────────────
class PolicyInput {
  final String id;
  final String title;
  final String description;
  final String policyText;
  final DateTime createdAt;
  final Map<String, dynamic>? validationResults;
  final List<String>? refinedOptions;
  final String? selectedRefinement;

  PolicyInput({
    required this.id,
    required this.title,
    required this.description,
    required this.policyText,
    required this.createdAt,
    this.validationResults,
    this.refinedOptions,
    this.selectedRefinement,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'policyText': policyText,
      'createdAt': createdAt.toIso8601String(),
      'validationResults': validationResults,
      'refinedOptions': refinedOptions,
      'selectedRefinement': selectedRefinement,
    };
  }
}

// ── RAG Context ────────────────────────────────────────────────────────────────
class RAGContext {
  final String query;
  final List<Map<String, dynamic>> sources;
  final String context;
  final DateTime retrievedAt;

  RAGContext({
    required this.query,
    required this.sources,
    required this.context,
    required this.retrievedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'sources': sources,
      'context': context,
      'retrievedAt': retrievedAt.toIso8601String(),
    };
  }
}
