import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/system_models.dart';

class GatekeeperService {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // TODO: Replace with your actual API key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  /// Validates a policy using Gemini 1.5 Flash
  static Future<PolicyValidationResult> validatePolicy(String policyText) async {
    try {
      final prompt = _buildValidationPrompt(policyText);
      
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseValidationResult(text);
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      return PolicyValidationResult(
        isValid: false,
        reasoning: 'Validation failed due to error',
        economicLever: [],
        targetGroups: [],
        refinedOptions: [],
        error: 'Validation failed: $e',
      );
    }
  }

  static String _buildValidationPrompt(String policyText) {
    return '''
You are PolicyIQ's Gatekeeper, an AI system that validates Malaysian government policies for simulation viability.

Analyze this policy and determine if it's viable for multi-agent simulation:

POLICY TEXT:
"$policyText"

VALIDATION CRITERIA:
1. Must have at least one clear economic lever (cash flow, cost, or access impact)
2. Must specify target demographics/groups 
3. Must be implementable within Malaysian context
4. Must have measurable outcomes

RESPONSE FORMAT (JSON only):
{
  "isValid": true/false,
  "reasoning": "Brief explanation of why valid or invalid",
  "economicLever": ["disposable_income_delta", "operational_expense_index", etc],
  "targetGroups": ["B40", "M40", "T20", "Urban", "Rural", etc],
  "refinedOptions": [
    {
      "title": "Refined Policy Option 1",
      "description": "Mathematically viable version",
      "economicLever": "specific_knob",
      "targetGroups": ["specific_groups"],
      "impactEstimate": "brief impact description"
    }
  ]
}

If invalid, provide 3 specific, mathematically viable refined options.
''';
  }

  static PolicyValidationResult _parseValidationResult(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonString = response.substring(jsonStart, jsonEnd);
      
      final data = jsonDecode(jsonString);
      
      final refinedOptions = <String>[];
      if (data['refinedOptions'] != null) {
        for (final option in data['refinedOptions']) {
          refinedOptions.add('${option['title']}: ${option['description']}');
        }
      }

      return PolicyValidationResult(
        isValid: data['isValid'] ?? false,
        reasoning: data['reasoning'] ?? '',
        economicLever: List<String>.from(data['economicLever'] ?? []),
        targetGroups: List<String>.from(data['targetGroups'] ?? []),
        refinedOptions: refinedOptions,
        error: null,
      );
    } catch (e) {
      return PolicyValidationResult(
        isValid: false,
        reasoning: 'Failed to parse validation result',
        economicLever: [],
        targetGroups: [],
        refinedOptions: [],
        error: 'Failed to parse validation result: $e',
      );
    }
  }
}

class PolicyValidationResult {
  final bool isValid;
  final String reasoning;
  final List<String> economicLever;
  final List<String> targetGroups;
  final List<String> refinedOptions;
  final String? error;

  PolicyValidationResult({
    required this.isValid,
    required this.reasoning,
    required this.economicLever,
    required this.targetGroups,
    required this.refinedOptions,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'reasoning': reasoning,
      'economicLever': economicLever,
      'targetGroups': targetGroups,
      'refinedOptions': refinedOptions,
      'error': error,
    };
  }
}
