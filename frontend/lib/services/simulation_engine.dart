import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/system_models.dart';

class SimulationEngine {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // TODO: Replace with your actual API key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  /// Runs a complete simulation tick for all agents
  static Future<SimulationTickResult> runSimulationTick(
    List<AgentDNA> agents,
    GlobalState globalState,
    List<SubLayer> subLayers,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // Step 1: State Broadcast
      final environmentState = _calculateEnvironmentState(globalState, subLayers);
      
      // Step 2: Generate observation prompts for all agents
      final agentPrompts = <String, String>{};
      for (final agent in agents) {
        agentPrompts[agent.id] = _generateObservationPrompt(agent, environmentState, globalState);
      }
      
      // Step 3: Parallel execution of all agents
      final agentDecisions = await _executeAgentsInParallel(agentPrompts);
      
      // Step 4: Aggregate results and update agents
      final updatedAgents = <AgentDNA>[];
      for (final agent in agents) {
        final decision = agentDecisions[agent.id];
        if (decision != null) {
          updatedAgents.add(_updateAgentState(agent, decision));
        } else {
          updatedAgents.add(agent); // No decision received
        }
      }
      
      // Step 5: Calculate macro metrics
      final macroMetrics = _calculateMacroMetrics(updatedAgents, globalState);
      
      // Step 6: Check for breaking points and anomalies
      final anomalies = _detectAnomalies(updatedAgents);
      
      final endTime = DateTime.now();
      
      return SimulationTickResult(
        success: true,
        tickNumber: globalState.currentTick + 1,
        agents: updatedAgents,
        agentDecisions: agentDecisions,
        macroMetrics: macroMetrics,
        anomalies: anomalies,
        environmentState: environmentState,
        duration: endTime.difference(startTime),
        error: null,
      );
      
    } catch (e) {
      return SimulationTickResult(
        success: false,
        tickNumber: globalState.currentTick + 1,
        agents: agents,
        agentDecisions: {},
        macroMetrics: {},
        anomalies: [],
        environmentState: {},
        duration: DateTime.now().difference(startTime),
        error: 'Simulation tick failed: $e',
      );
    }
  }

  /// Calculates the current environment state based on knobs and sub-layers
  static Map<String, dynamic> _calculateEnvironmentState(GlobalState globalState, List<SubLayer> subLayers) {
    final environment = <String, dynamic>{};
    
    // Base knob values
    for (final entry in globalState.knobValues.entries) {
      environment['knob_${entry.key.name}'] = entry.value;
    }
    
    // Sub-layer impacts
    for (final subLayer in subLayers) {
      final parentValue = globalState.knobValues[subLayer.parentKnob] ?? 0.0;
      final impact = parentValue * subLayer.impactMultiplier;
      environment['sublayer_${subLayer.id}'] = impact;
    }
    
    // Derived metrics
    environment['overall_stress'] = globalState.overallSystemStress;
    environment['economic_pressure'] = _calculateEconomicPressure(globalState.knobValues);
    environment['social_stability'] = _calculateSocialStability(globalState.knobValues);
    
    return environment;
  }

  static double _calculateEconomicPressure(Map<UniversalKnobType, double> knobValues) {
    final disposablePressure = (1.0 - (knobValues[UniversalKnobType.disposableIncomeDelta]! + 1.0) / 2.0);
    final expensePressure = (knobValues[UniversalKnobType.operationalExpenseIndex]! + 1.0) / 2.0;
    final capitalPressure = (knobValues[UniversalKnobType.capitalAccessPressure]! + 1.0) / 2.0;
    
    return (disposablePressure + expensePressure + capitalPressure) / 3.0;
  }

  static double _calculateSocialStability(Map<UniversalKnobType, double> knobValues) {
    final equity = (knobValues[UniversalKnobType.socialEquityWeight]! + 1.0) / 2.0;
    final trust = (knobValues[UniversalKnobType.systemicTrustBaseline]! + 1.0) / 2.0;
    final friction = 1.0 - ((knobValues[UniversalKnobType.systemicFriction]! + 1.0) / 2.0);
    
    return (equity + trust + friction) / 3.0;
  }

  /// Generates personalized observation prompt for each agent
  static String _generateObservationPrompt(AgentDNA agent, Map<String, dynamic> environmentState, GlobalState globalState) {
    return '''
You are a Digital Malaysian citizen participating in a policy simulation. Respond as this specific person:

AGENT PROFILE:
- Name: ${agent.name}
- Income Tier: ${agent.incomeTier.name} (Monthly Income: RM${agent.monthlyIncomeRm.toStringAsFixed(0)})
- Occupation: ${agent.occupationType.name}
- Location: ${agent.locationMatrix.name}
- Dependents: ${agent.dependentsCount}
- Current Financial Health: ${(agent.financialHealth * 100).toStringAsFixed(1)}%
- Current Sentiment: ${(agent.currentSentiment * 100).toStringAsFixed(1)}%
- Monthly Disposable Buffer: RM${agent.disposableBufferRm.toStringAsFixed(0)}
- Liquid Savings: RM${agent.liquidSavingsRm.toStringAsFixed(0)}
- Debt-to-Income Ratio: ${(agent.debtToIncomeRatio * 100).toStringAsFixed(1)}%

CURRENT ENVIRONMENT (Tick ${globalState.currentTick}):
${environmentState.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

SENSITIVITY PROFILE:
${agent.sensitivityWeights.entries.map((e) => '- ${e.key.name}: ${(e.value! * 100).toStringAsFixed(1)}%').join('\n')}

TASK:
Based on your profile and the current environment, decide what you will do this month. Consider:
1. Your financial situation and obligations
2. How the policy changes affect you specifically
3. Your family's needs and future plans
4. Your personal values and concerns

RESPONSE FORMAT (JSON only):
{
  "action": "Specific action you will take (e.g., 'reduce spending', 'seek additional income', 'apply for aid', 'maintain current lifestyle')",
  "sentiment": "New sentiment score (-1.0 to 1.0)",
  "financialChange": "Financial impact this month (positive for income increase, negative for expenses)",
  "monologue": "Brief internal monologue explaining your decision (2-3 sentences)",
  "metadata": {
    "reasoning": "Brief explanation of your decision",
    "concerns": ["concern1", "concern2"],
    "hopes": ["hope1", "hope2"]
  }
}

Be realistic and reflect your demographic profile. B40 agents should prioritize basic needs, M40 balance stability and aspirations, T20 focus on investments and quality of life.
''';
  }

  /// Executes all agents in parallel using concurrent HTTP requests
  static Future<Map<String, AgentDecision>> _executeAgentsInParallel(Map<String, String> agentPrompts) async {
    final futures = <Future<AgentDecision?>>[];
    
    for (final entry in agentPrompts.entries) {
      futures.add(_executeAgent(entry.key, entry.value));
    }
    
    final results = await Future.wait(futures);
    final decisions = <String, AgentDecision>{};
    
    for (int i = 0; i < agentPrompts.keys.length; i++) {
      final agentId = agentPrompts.keys.elementAt(i);
      final decision = results[i];
      if (decision != null) {
        decisions[agentId] = decision;
      }
    }
    
    return decisions;
  }

  /// Executes a single agent decision
  static Future<AgentDecision?> _executeAgent(String agentId, String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 512,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract JSON from response
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd);
          final decisionData = jsonDecode(jsonString);
          return AgentDecision(
            agentId: agentId,
            action: decisionData['action'] ?? 'No action',
            sentiment: (decisionData['sentiment'] as num?)?.toDouble() ?? 0.0,
            financialChange: (decisionData['financialChange'] as num?)?.toDouble() ?? 0.0,
            monologue: decisionData['monologue'] ?? 'No monologue',
            metadata: decisionData['metadata'] ?? {},
          );
        }
      }
    } catch (e) {
      // Log error but don't fail the entire simulation
      print('Agent $agentId execution failed: $e');
    }
    
    return null;
  }

  /// Updates agent state based on decision
  static AgentDNA _updateAgentState(AgentDNA agent, AgentDecision decision) {
    // Update sentiment
    final newSentiment = (agent.currentSentiment + decision.sentiment) / 2.0;
    
    // Update financial health
    final financialImpact = decision.financialChange / agent.monthlyIncomeRm;
    final newFinancialHealth = (agent.financialHealth + financialImpact).clamp(0.0, 1.0);
    
    // Update monologue history
    final newMonologueHistory = List<String>.from(agent.monologueHistory);
    newMonologueHistory.add(decision.monologue);
    
    // Check for breaking point
    String anomalyFlag = agent.anomalyFlag;
    if (newFinancialHealth <= 0.0 || newSentiment <= -1.0) {
      anomalyFlag = 'CRITICAL';
    } else if (newFinancialHealth <= 0.2 || newSentiment <= -0.5) {
      anomalyFlag = 'WATCH';
    } else {
      anomalyFlag = 'NORMAL';
    }
    
    return AgentDNA(
      id: agent.id,
      name: agent.name,
      incomeTier: agent.incomeTier,
      occupationType: agent.occupationType,
      locationMatrix: agent.locationMatrix,
      monthlyIncomeRm: agent.monthlyIncomeRm,
      liquidSavingsRm: agent.liquidSavingsRm,
      debtToIncomeRatio: agent.debtToIncomeRatio,
      dependentsCount: agent.dependentsCount,
      digitalReadinessScore: agent.digitalReadinessScore,
      subsidyFlags: agent.subsidyFlags,
      sensitivityWeights: agent.sensitivityWeights,
      currentSentiment: newSentiment,
      financialHealth: newFinancialHealth,
      monologueHistory: newMonologueHistory,
      currentState: {
        'lastAction': decision.action,
        'lastFinancialChange': decision.financialChange,
        'lastDecisionTime': DateTime.now().toIso8601String(),
      },
      anomalyFlag: anomalyFlag,
    );
  }

  /// Calculates macro metrics from all agents
  static Map<String, dynamic> _calculateMacroMetrics(List<AgentDNA> agents, GlobalState globalState) {
    final totalAgents = agents.length;
    
    // Sentiment distribution
    final avgSentiment = agents.map((a) => a.currentSentiment).reduce((a, b) => a + b) / totalAgents;
    final negativeSentiment = agents.where((a) => a.currentSentiment < -0.3).length;
    final positiveSentiment = agents.where((a) => a.currentSentiment > 0.3).length;
    
    // Financial health distribution
    final avgFinancialHealth = agents.map((a) => a.financialHealth).reduce((a, b) => a + b) / totalAgents;
    final criticalFinancial = agents.where((a) => a.financialHealth <= 0.2).length;
    final stableFinancial = agents.where((a) => a.financialHealth >= 0.7).length;
    
    // Anomaly distribution
    final criticalAgents = agents.where((a) => a.anomalyFlag == 'CRITICAL').length;
    final watchAgents = agents.where((a) => a.anomalyFlag == 'WATCH').length;
    
    // Income tier distribution
    final b40Count = agents.where((a) => a.incomeTier == IncomeTier.B40).length;
    final m40Count = agents.where((a) => a.incomeTier == IncomeTier.M40).length;
    final t20Count = agents.where((a) => a.incomeTier == IncomeTier.T20).length;
    
    return {
      'totalAgents': totalAgents,
      'avgSentiment': avgSentiment,
      'negativeSentimentCount': negativeSentiment,
      'positiveSentimentCount': positiveSentiment,
      'avgFinancialHealth': avgFinancialHealth,
      'criticalFinancialCount': criticalFinancial,
      'stableFinancialCount': stableFinancial,
      'criticalAgentsCount': criticalAgents,
      'watchAgentsCount': watchAgents,
      'b40Count': b40Count,
      'm40Count': m40Count,
      't20Count': t20Count,
      'overallSystemStress': globalState.overallSystemStress,
      'economicPressure': _calculateEconomicPressure(globalState.knobValues),
      'socialStability': _calculateSocialStability(globalState.knobValues),
    };
  }

  /// Detects anomalies and breaking points
  static List<AnomalyDetection> _detectAnomalies(List<AgentDNA> agents) {
    final anomalies = <AnomalyDetection>[];
    
    for (final agent in agents) {
      if (agent.isAtBreakingPoint) {
        anomalies.add(AnomalyDetection(
          agentId: agent.id,
          type: AnomalyType.breakingPoint,
          severity: AnomalySeverity.critical,
          description: 'Agent ${agent.name} has reached breaking point (Financial: ${(agent.financialHealth * 100).toStringAsFixed(1)}%, Sentiment: ${(agent.currentSentiment * 100).toStringAsFixed(1)}%)',
          timestamp: DateTime.now(),
        ));
      }
      
      // Check for rapid sentiment drops
      if (agent.monologueHistory.length >= 2) {
        // This would need more sophisticated logic to track rapid changes
        // For now, just flag critical agents
        if (agent.anomalyFlag == 'CRITICAL') {
          anomalies.add(AnomalyDetection(
            agentId: agent.id,
            type: AnomalyType.sentimentCrisis,
            severity: AnomalySeverity.high,
            description: 'Agent ${agent.name} experiencing severe distress',
            timestamp: DateTime.now(),
          ));
        }
      }
    }
    
    return anomalies;
  }
}

class SimulationTickResult {
  final bool success;
  final int tickNumber;
  final List<AgentDNA> agents;
  final Map<String, AgentDecision> agentDecisions;
  final Map<String, dynamic> macroMetrics;
  final List<AnomalyDetection> anomalies;
  final Map<String, dynamic> environmentState;
  final Duration duration;
  final String? error;

  SimulationTickResult({
    required this.success,
    required this.tickNumber,
    required this.agents,
    required this.agentDecisions,
    required this.macroMetrics,
    required this.anomalies,
    required this.environmentState,
    required this.duration,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'tickNumber': tickNumber,
      'agents': agents.map((a) => a.toJson()).toList(),
      'agentDecisions': agentDecisions.map((k, v) => MapEntry(k, v.toJson())),
      'macroMetrics': macroMetrics,
      'anomalies': anomalies.map((a) => a.toJson()).toList(),
      'environmentState': environmentState,
      'duration': duration.inMilliseconds,
      'error': error,
    };
  }
}

enum AnomalyType {
  breakingPoint,
  sentimentCrisis,
  financialCrisis,
  loopholeExploitation,
}

enum AnomalySeverity {
  low,
  medium,
  high,
  critical,
}

class AnomalyDetection {
  final String agentId;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String description;
  final DateTime timestamp;

  AnomalyDetection({
    required this.agentId,
    required this.type,
    required this.severity,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'type': type.name,
      'severity': severity.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
