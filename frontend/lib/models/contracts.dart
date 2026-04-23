// contracts.dart — Dart model classes for all API Contracts (Pre-A through E).
//
// Mirrors the Pydantic schemas in backend/schemas.py exactly so that
// JSON serialisation/deserialisation is symmetric.

// ─── Contract Pre-A ──────────────────────────────────────────────────────────

/// Contract Pre-A: request body for POST /validate-policy
class ValidatePolicyRequest {
  final String rawPolicyText;

  const ValidatePolicyRequest({required this.rawPolicyText});

  Map<String, dynamic> toJson() => {'raw_policy_text': rawPolicyText};
}

// ─── Contract Pre-B ──────────────────────────────────────────────────────────

/// Contract Pre-B: response from POST /validate-policy
class ValidatePolicyResponse {
  final bool isValid;
  final String? rejectionReason;
  final List<String> refinedOptions;

  const ValidatePolicyResponse({
    required this.isValid,
    this.rejectionReason,
    this.refinedOptions = const [],
  });

  factory ValidatePolicyResponse.fromJson(Map<String, dynamic> json) {
    return ValidatePolicyResponse(
      isValid: json['is_valid'] as bool,
      rejectionReason: json['rejection_reason'] as String?,
      refinedOptions: (json['refined_options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

// ─── Contract A ──────────────────────────────────────────────────────────────

/// Optional manual overrides for the 8 Universal Knobs.
class KnobOverrides {
  final double? disposableIncomeDelta;
  final double? operationalExpenseIndex;
  final double? capitalAccessPressure;
  final double? systemicFriction;
  final double? socialEquityWeight;
  final double? systemicTrustBaseline;
  final double? futureMobilityIndex;
  final double? ecologicalPressure;

  const KnobOverrides({
    this.disposableIncomeDelta,
    this.operationalExpenseIndex,
    this.capitalAccessPressure,
    this.systemicFriction,
    this.socialEquityWeight,
    this.systemicTrustBaseline,
    this.futureMobilityIndex,
    this.ecologicalPressure,
  });

  Map<String, dynamic> toJson() => {
        if (disposableIncomeDelta != null)
          'disposable_income_delta': disposableIncomeDelta,
        if (operationalExpenseIndex != null)
          'operational_expense_index': operationalExpenseIndex,
        if (capitalAccessPressure != null)
          'capital_access_pressure': capitalAccessPressure,
        if (systemicFriction != null) 'systemic_friction': systemicFriction,
        if (socialEquityWeight != null)
          'social_equity_weight': socialEquityWeight,
        if (systemicTrustBaseline != null)
          'systemic_trust_baseline': systemicTrustBaseline,
        if (futureMobilityIndex != null)
          'future_mobility_index': futureMobilityIndex,
        if (ecologicalPressure != null)
          'ecological_pressure': ecologicalPressure,
      };
}

/// Contract A: request body for POST /simulate
class SimulateRequest {
  final String policyText;
  final int simulationTicks;
  final int agentCount;
  final KnobOverrides knobOverrides;

  const SimulateRequest({
    required this.policyText,
    this.simulationTicks = 4,
    this.agentCount = 5,
    this.knobOverrides = const KnobOverrides(),
  });

  Map<String, dynamic> toJson() => {
        'policy_text': policyText,
        'simulation_ticks': simulationTicks,
        'agent_count': agentCount,
        'knob_overrides': knobOverrides.toJson(),
      };
}

// ─── Contract D ──────────────────────────────────────────────────────────────

/// Contract D: a single agent's decision for one tick (as returned inside Contract E).
class AgentDecision {
  final String agentId;
  final String action;
  final double sentimentScore;
  final double financialHealthChange;
  final String internalMonologue;
  final bool isBreakingPoint;

  const AgentDecision({
    required this.agentId,
    required this.action,
    required this.sentimentScore,
    required this.financialHealthChange,
    required this.internalMonologue,
    required this.isBreakingPoint,
  });

  factory AgentDecision.fromJson(Map<String, dynamic> json) {
    return AgentDecision(
      agentId: json['agent_id'] as String,
      action: json['action'] as String,
      sentimentScore: (json['sentiment_score'] as num).toDouble(),
      financialHealthChange:
          (json['financial_health_change'] as num).toDouble(),
      internalMonologue: json['internal_monologue'] as String,
      isBreakingPoint: json['is_breaking_point'] as bool,
    );
  }
}

// ─── Contract E ──────────────────────────────────────────────────────────────

class SimulationMetadata {
  final String policy;
  final int totalTicks;

  const SimulationMetadata({required this.policy, required this.totalTicks});

  factory SimulationMetadata.fromJson(Map<String, dynamic> json) =>
      SimulationMetadata(
        policy: json['policy'] as String,
        totalTicks: json['total_ticks'] as int,
      );
}

class MacroSummary {
  final double overallSentimentShift;
  final double inequalityDelta;

  const MacroSummary(
      {required this.overallSentimentShift, required this.inequalityDelta});

  factory MacroSummary.fromJson(Map<String, dynamic> json) => MacroSummary(
        overallSentimentShift:
            (json['overall_sentiment_shift'] as num).toDouble(),
        inequalityDelta: (json['inequality_delta'] as num).toDouble(),
      );
}

class TickSummary {
  final int tickId;
  final double averageSentiment;
  final List<AgentDecision> agentActions;

  const TickSummary({
    required this.tickId,
    required this.averageSentiment,
    required this.agentActions,
  });

  factory TickSummary.fromJson(Map<String, dynamic> json) => TickSummary(
        tickId: json['tick_id'] as int,
        averageSentiment: (json['average_sentiment'] as num).toDouble(),
        agentActions: (json['agent_actions'] as List<dynamic>)
            .map((e) => AgentDecision.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Anomaly {
  final String type;
  final String agentId;
  final String demographic;
  final String reason;

  const Anomaly({
    required this.type,
    required this.agentId,
    required this.demographic,
    required this.reason,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) => Anomaly(
        type: json['type'] as String,
        agentId: json['agent_id'] as String,
        demographic: json['demographic'] as String,
        reason: json['reason'] as String,
      );
}

/// Contract E: full dashboard payload — the final SSE "complete" event.
class SimulateResponse {
  final SimulationMetadata simulationMetadata;
  final MacroSummary macroSummary;
  final List<TickSummary> timeline;
  final List<Anomaly> anomalies;
  final String aiPolicyRecommendation;

  const SimulateResponse({
    required this.simulationMetadata,
    required this.macroSummary,
    required this.timeline,
    required this.anomalies,
    required this.aiPolicyRecommendation,
  });

  factory SimulateResponse.fromJson(Map<String, dynamic> json) =>
      SimulateResponse(
        simulationMetadata: SimulationMetadata.fromJson(
            json['simulation_metadata'] as Map<String, dynamic>),
        macroSummary: MacroSummary.fromJson(
            json['macro_summary'] as Map<String, dynamic>),
        timeline: (json['timeline'] as List<dynamic>)
            .map((e) => TickSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        anomalies: (json['anomalies'] as List<dynamic>)
            .map((e) => Anomaly.fromJson(e as Map<String, dynamic>))
            .toList(),
        aiPolicyRecommendation: json['ai_policy_recommendation'] as String,
      );
}