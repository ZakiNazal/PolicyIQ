import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/system_models.dart';
import '../services/simulation_engine.dart';

class AnomalyEngine {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // TODO: Replace with your actual API key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  /// Analyzes simulation timeline and suggests policy mitigations
  static Future<PolicyMitigationResult> generatePolicyMitigation(
    List<SimulationTickResult> timeline,
    PolicyInput originalPolicy,
    List<AnomalyDetection> anomalies,
  ) async {
    try {
      final prompt = _buildMitigationPrompt(timeline, originalPolicy, anomalies);
      
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseMitigationResult(text);
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      return PolicyMitigationResult(
        success: false,
        mitigation: 'Failed to generate policy mitigation: $e',
        confidence: 0.0,
        recommendedActions: [],
        error: e.toString(),
      );
    }
  }

  static String _buildMitigationPrompt(
    List<SimulationTickResult> timeline,
    PolicyInput originalPolicy,
    List<AnomalyDetection> anomalies,
  ) {
    final timelineSummary = timeline.map((tick) => 
      'Tick ${tick.tickNumber}: ${tick.anomalies.length} anomalies, Avg Sentiment: ${(tick.macroMetrics['avgSentiment'] as double? ?? 0.0 * 100).toStringAsFixed(1)}%, Critical Agents: ${tick.macroMetrics['criticalAgentsCount']}'
    ).join('\n');

    final anomalySummary = anomalies.map((a) => 
      '- ${a.agentId}: ${a.description} (Severity: ${a.severity.name})'
    ).join('\n');

    return '''
You are PolicyIQ's Anomaly Engine. Analyze this simulation timeline and suggest policy mitigations.

ORIGINAL POLICY:
${originalPolicy.policyText}

SIMULATION TIMELINE:
$timelineSummary

ANOMALIES DETECTED:
$anomalySummary

ANALYSIS TASK:
1. Identify patterns in agent distress
2. Detect policy loopholes or unintended consequences
3. Suggest specific policy adjustments to mitigate negative impacts

RESPONSE FORMAT (JSON only):
{
  "mitigation": "1-paragraph specific policy adjustment recommendation",
  "confidence": 0.0-1.0,
  "recommendedActions": [
    "Action 1: Specific adjustment",
    "Action 2: Targeted intervention",
    "Action 3: Implementation timeline"
  ],
  "riskAssessment": "Brief assessment of implementation risks",
  "expectedOutcome": "Expected improvement in agent outcomes"
}

Focus on practical, implementable solutions that address the root causes of agent distress.
''';
  }

  static PolicyMitigationResult _parseMitigationResult(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonString);
        
        return PolicyMitigationResult(
          success: true,
          mitigation: data['mitigation'] ?? 'No mitigation suggested',
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
          recommendedActions: List<String>.from(data['recommendedActions'] ?? []),
          riskAssessment: data['riskAssessment'] ?? 'No risk assessment provided',
          expectedOutcome: data['expectedOutcome'] ?? 'No outcome prediction provided',
          error: null,
        );
      }
    } catch (e) {
      return PolicyMitigationResult(
        success: false,
        mitigation: 'Failed to parse mitigation result: $e',
        confidence: 0.0,
        recommendedActions: [],
        error: e.toString(),
      );
    }
    
    return PolicyMitigationResult(
      success: false,
      mitigation: 'No valid response received',
      confidence: 0.0,
      recommendedActions: [],
      error: 'Invalid response format',
    );
  }

  /// Detects loophole exploitation patterns
  static List<LoopholeDetection> detectLoopholeExploitation(
    List<SimulationTickResult> timeline,
    List<AgentDNA> agents,
  ) {
    final detections = <LoopholeDetection>[];

    for (final agent in agents) {
      final agentTimeline = _extractAgentTimeline(timeline, agent.id);
      
      // Check for rapid financial gains
      if (_detectRapidFinancialGain(agentTimeline)) {
        detections.add(LoopholeDetection(
          agentId: agent.id,
          type: LoopholeType.financialExploitation,
          description: 'Agent ${agent.name} showing unusual financial gain patterns',
          severity: LoopholeSeverity.high,
          evidence: agentTimeline.map((t) => 'Tick ${t.tick}: +RM${t.financialChange.toStringAsFixed(0)}').toList(),
        ));
      }
      
      // Check for sentiment manipulation
      if (_detectSentimentManipulation(agentTimeline)) {
        detections.add(LoopholeDetection(
          agentId: agent.id,
          type: LoopholeType.sentimentManipulation,
          description: 'Agent ${agent.name} showing artificial sentiment patterns',
          severity: LoopholeSeverity.medium,
          evidence: agentTimeline.map((t) => 'Tick ${t.tick}: Sentiment ${t.sentiment.toStringAsFixed(2)}').toList(),
        ));
      }
      
      // Check for policy gaming
      if (_detectPolicyGaming(agentTimeline)) {
        detections.add(LoopholeDetection(
          agentId: agent.id,
          type: LoopholeType.policyGaming,
          description: 'Agent ${agent.name} appears to be gaming policy mechanisms',
          severity: LoopholeSeverity.medium,
          evidence: agentTimeline.map((t) => 'Tick ${t.tick}: ${t.action}').toList(),
        ));
      }
    }

    return detections;
  }

  static List<AgentTimelineEntry> _extractAgentTimeline(List<SimulationTickResult> timeline, String agentId) {
    final entries = <AgentTimelineEntry>[];
    
    for (final tick in timeline) {
      final decision = tick.agentDecisions[agentId];
      if (decision != null) {
        entries.add(AgentTimelineEntry(
          tick: tick.tickNumber,
          action: decision.action,
          sentiment: decision.sentiment,
          financialChange: decision.financialChange,
          monologue: decision.monologue,
        ));
      }
    }
    
    return entries;
  }

  static bool _detectRapidFinancialGain(List<AgentTimelineEntry> timeline) {
    if (timeline.length < 3) return false;
    
    // Check for consistent positive financial changes
    final recentChanges = timeline.length >= 3 
        ? timeline.skip(timeline.length - 3).map((e) => e.financialChange).toList()
        : timeline.map((e) => e.financialChange).toList();
    return recentChanges.every((change) => change > 0) && 
           recentChanges.reduce((a, b) => a + b) > 1000; // Total gain > RM1000
  }

  static bool _detectSentimentManipulation(List<AgentTimelineEntry> timeline) {
    if (timeline.length < 5) return false;
    
    // Flag if sentiment is consistently high despite negative financial changes
    final negativeFinancialTicks = timeline.where((e) => e.financialChange < 0).length;
    final positiveSentimentTicks = timeline.where((e) => e.sentiment > 0.5).length;
    
    return negativeFinancialTicks >= 3 && positiveSentimentTicks >= negativeFinancialTicks;
  }

  static bool _detectPolicyGaming(List<AgentTimelineEntry> timeline) {
    if (timeline.length < 2) return false;
    
    // Check for repetitive, optimized actions
    final actions = timeline.map((e) => e.action.toLowerCase()).toList();
    final uniqueActions = actions.toSet();
    
    // Flag if agent uses very few different actions (suggests optimization)
    return uniqueActions.length <= 2 && timeline.length >= 5;
  }

  /// Generates comprehensive anomaly report
  static AnomalyReport generateAnomalyReport(
    List<SimulationTickResult> timeline,
    List<AnomalyDetection> anomalies,
    List<LoopholeDetection> loopholes,
    PolicyMitigationResult? mitigation,
  ) {
    final totalTicks = timeline.length;
    final totalAnomalies = anomalies.length;
    final totalLoopholes = loopholes.length;
    
    // Calculate anomaly trends
    final anomalyTrend = _calculateAnomalyTrend(timeline);
    
    // Identify most affected demographics
    final affectedDemographics = _identifyAffectedDemographics(anomalies);
    
    // Calculate system stability score
    final stabilityScore = _calculateSystemStability(timeline, anomalies, loopholes);
    
    return AnomalyReport(
      totalTicks: totalTicks,
      totalAnomalies: totalAnomalies,
      totalLoopholes: totalLoopholes,
      anomalyTrend: anomalyTrend,
      affectedDemographics: affectedDemographics,
      systemStabilityScore: stabilityScore,
      criticalIssues: anomalies.where((a) => a.severity == AnomalySeverity.critical).length,
      policyMitigation: mitigation,
      recommendations: _generateRecommendations(anomalies, loopholes, stabilityScore),
      generatedAt: DateTime.now(),
    );
  }

  static AnomalyTrend _calculateAnomalyTrend(List<SimulationTickResult> timeline) {
    if (timeline.length < 2) return AnomalyTrend.stable;
    
    final recentAnomalies = timeline.length >= 5 
        ? timeline.skip(timeline.length - 5).map((t) => t.anomalies.length).toList()
        : timeline.map((t) => t.anomalies.length).toList();
    final earlierAnomalies = timeline.skip(timeline.length - 10).take(5).map((t) => t.anomalies.length).toList();
    
    if (earlierAnomalies.isEmpty) return AnomalyTrend.stable;
    
    final recentAvg = recentAnomalies.reduce((a, b) => a + b) / recentAnomalies.length;
    final earlierAvg = earlierAnomalies.reduce((a, b) => a + b) / earlierAnomalies.length;
    
    if (recentAvg > earlierAvg * 1.5) return AnomalyTrend.increasing;
    if (recentAvg < earlierAvg * 0.5) return AnomalyTrend.decreasing;
    return AnomalyTrend.stable;
  }

  static Map<String, int> _identifyAffectedDemographics(List<AnomalyDetection> anomalies) {
    final demographics = <String, int>{};
    
    // This would need access to agent data to properly categorize
    // For now, return placeholder data
    demographics['B40'] = anomalies.where((a) => a.agentId.startsWith('MY-0')).length;
    demographics['M40'] = anomalies.where((a) => a.agentId.startsWith('MY-1')).length;
    demographics['T20'] = anomalies.where((a) => a.agentId.startsWith('MY-2')).length;
    
    return demographics;
  }

  static double _calculateSystemStability(
    List<SimulationTickResult> timeline,
    List<AnomalyDetection> anomalies,
    List<LoopholeDetection> loopholes,
  ) {
    if (timeline.isEmpty) return 1.0;
    
    final totalAgents = timeline.first.agents.length;
    final criticalAnomalies = anomalies.where((a) => a.severity == AnomalySeverity.critical).length;
    final highSeverityLoopholes = loopholes.where((l) => l.severity == LoopholeSeverity.high).length;
    
    // Base stability starts at 1.0, reduced by issues
    double stability = 1.0;
    stability -= (criticalAnomalies / totalAgents) * 0.5; // Critical anomalies have high impact
    stability -= (highSeverityLoopholes / totalAgents) * 0.3; // Loopholes have medium impact
    
    return stability.clamp(0.0, 1.0);
  }

  static List<String> _generateRecommendations(
    List<AnomalyDetection> anomalies,
    List<LoopholeDetection> loopholes,
    double stabilityScore,
  ) {
    final recommendations = <String>[];
    
    if (stabilityScore < 0.3) {
      recommendations.add('URGENT: System stability critical. Consider immediate policy revision.');
    }
    
    if (anomalies.where((a) => a.type == AnomalyType.breakingPoint).length > 5) {
      recommendations.add('Multiple agents at breaking point. Strengthen social safety nets.');
    }
    
    if (loopholes.where((l) => l.type == LoopholeType.financialExploitation).isNotEmpty) {
      recommendations.add('Financial loopholes detected. Add policy safeguards and verification mechanisms.');
    }
    
    if (stabilityScore < 0.7) {
      recommendations.add('System stability below optimal levels. Monitor agent sentiment closely.');
    }
    
    return recommendations;
  }
}

class PolicyMitigationResult {
  final bool success;
  final String mitigation;
  final double confidence;
  final List<String> recommendedActions;
  final String? riskAssessment;
  final String? expectedOutcome;
  final String? error;

  PolicyMitigationResult({
    required this.success,
    required this.mitigation,
    required this.confidence,
    required this.recommendedActions,
    this.riskAssessment,
    this.expectedOutcome,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'mitigation': mitigation,
      'confidence': confidence,
      'recommendedActions': recommendedActions,
      'riskAssessment': riskAssessment,
      'expectedOutcome': expectedOutcome,
      'error': error,
    };
  }
}

class LoopholeDetection {
  final String agentId;
  final LoopholeType type;
  final String description;
  final LoopholeSeverity severity;
  final List<String> evidence;

  LoopholeDetection({
    required this.agentId,
    required this.type,
    required this.description,
    required this.severity,
    required this.evidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'type': type.name,
      'description': description,
      'severity': severity.name,
      'evidence': evidence,
    };
  }
}

enum LoopholeType {
  financialExploitation,
  sentimentManipulation,
  policyGaming,
  eligibilityAbuse,
}

enum LoopholeSeverity {
  low,
  medium,
  high,
  critical,
}

class AgentTimelineEntry {
  final int tick;
  final String action;
  final double sentiment;
  final double financialChange;
  final String monologue;

  AgentTimelineEntry({
    required this.tick,
    required this.action,
    required this.sentiment,
    required this.financialChange,
    required this.monologue,
  });
}

enum AnomalyTrend {
  stable,
  increasing,
  decreasing,
}

class AnomalyReport {
  final int totalTicks;
  final int totalAnomalies;
  final int totalLoopholes;
  final AnomalyTrend anomalyTrend;
  final Map<String, int> affectedDemographics;
  final double systemStabilityScore;
  final int criticalIssues;
  final PolicyMitigationResult? policyMitigation;
  final List<String> recommendations;
  final DateTime generatedAt;

  AnomalyReport({
    required this.totalTicks,
    required this.totalAnomalies,
    required this.totalLoopholes,
    required this.anomalyTrend,
    required this.affectedDemographics,
    required this.systemStabilityScore,
    required this.criticalIssues,
    this.policyMitigation,
    required this.recommendations,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalTicks': totalTicks,
      'totalAnomalies': totalAnomalies,
      'totalLoopholes': totalLoopholes,
      'anomalyTrend': anomalyTrend.name,
      'affectedDemographics': affectedDemographics,
      'systemStabilityScore': systemStabilityScore,
      'criticalIssues': criticalIssues,
      'policyMitigation': policyMitigation?.toJson(),
      'recommendations': recommendations,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
