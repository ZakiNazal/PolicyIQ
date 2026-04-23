import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/system_models.dart';

class DecompositionService {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // TODO: Replace with your actual API key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  /// Decomposes policy into 3-5 Sub-Layers using Gemini
  static Future<DecompositionResult> decomposePolicy(
    String policyText,
    List<String> economicLevers,
    List<String> targetGroups,
  ) async {
    try {
      final prompt = _buildDecompositionPrompt(policyText, economicLevers, targetGroups);
      
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseDecompositionResult(text);
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      return DecompositionResult(
        success: false,
        error: 'Decomposition failed: $e',
        subLayers: [],
      );
    }
  }

  static String _buildDecompositionPrompt(
    String policyText,
    List<String> economicLevers,
    List<String> targetGroups,
  ) {
    return '''
You are PolicyIQ's Dynamic Decomposition engine. Transform this Malaysian policy into exactly 3-5 concrete Sub-Layers.

POLICY TEXT:
"$policyText"

AVAILABLE ECONOMIC LEVERS (Universal Knobs):
- disposable_income_delta: Direct cash flow changes
- operational_expense_index: Cost of living, inflation, subsidy cuts
- capital_access_pressure: Debt, borrowing stress, OPR changes
- systemic_friction: Time poverty, administrative red tape, PADU registration
- social_equity_weight: Perception of fairness, Gini coefficient impact
- systemic_trust_baseline: Social contract strength
- future_mobility_index: Upskilling, class mobility opportunities
- ecological_resource_pressure: Sustainability metrics

TARGET DEMOGRAPHICS:
Income Tiers: B40, M40, T20
Occupations: gig_worker, salaried_corporate, sme_owner, civil_servant, unemployed
Locations: urban, suburban, rural

REQUIREMENTS:
1. Exactly 3-5 Sub-Layers total (no more, no less)
2. Each Sub-Layer must specify target demographics array
3. Each Sub-Layer must have specific impact multiplier (-2.0 to 2.0)
4. Must be mathematically implementable
5. Must align with Malaysian context

RESPONSE FORMAT (JSON only):
{
  "subLayers": [
    {
      "id": "sublayer_1",
      "name": "Specific Sub-Layer Name",
      "description": "Detailed description of implementation",
      "parentKnob": "economic_lever_type",
      "targetDemographics": ["B40", "Urban", "gig_worker"],
      "impactMultiplier": 1.2
    }
  ]
}

Each Sub-Layer represents how the policy affects a specific demographic through a specific economic lever.
''';
  }

  static DecompositionResult _parseDecompositionResult(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonString = response.substring(jsonStart, jsonEnd);
      
      final data = jsonDecode(jsonString);
      final subLayersData = data['subLayers'] as List;
      
      final subLayers = <SubLayer>[];
      final knobColors = {
        UniversalKnobType.disposableIncomeDelta: const Color(0xFF00BCD4),
        UniversalKnobType.operationalExpenseIndex: const Color(0xFF4CAF50),
        UniversalKnobType.capitalAccessPressure: const Color(0xFFFF9800),
        UniversalKnobType.systemicFriction: const Color(0xFFF44336),
        UniversalKnobType.socialEquityWeight: const Color(0xFF9C27B0),
        UniversalKnobType.systemicTrustBaseline: const Color(0xFF2196F3),
        UniversalKnobType.futureMobilityIndex: const Color(0xFF009688),
        UniversalKnobType.ecologicalResourcePressure: const Color(0xFF795548),
      };

      for (final subLayerData in subLayersData) {
        final knobTypeStr = subLayerData['parentKnob'] as String;
        final knobType = UniversalKnobType.values.firstWhere(
          (k) => k.name == knobTypeStr,
          orElse: () => UniversalKnobType.disposableIncomeDelta,
        );

        subLayers.add(SubLayer(
          id: subLayerData['id'],
          name: subLayerData['name'],
          description: subLayerData['description'],
          parentKnob: knobType,
          targetDemographics: List<String>.from(subLayerData['targetDemographics']),
          impactMultiplier: (subLayerData['impactMultiplier'] as num).toDouble(),
          accentColor: knobColors[knobType] ?? const Color(0xFF00BCD4),
        ));
      }

      return DecompositionResult(
        success: true,
        subLayers: subLayers,
        error: null,
      );
    } catch (e) {
      return DecompositionResult(
        success: false,
        error: 'Failed to parse decomposition result: $e',
        subLayers: [],
      );
    }
  }
}

class DecompositionResult {
  final bool success;
  final List<SubLayer> subLayers;
  final String? error;

  DecompositionResult({
    required this.success,
    required this.subLayers,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'subLayers': subLayers.map((sl) => sl.toJson()).toList(),
      'error': error,
    };
  }
}
