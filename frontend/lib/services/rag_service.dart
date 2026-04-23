import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/system_models.dart';

class RAGService {
  static const String _vertexAiSearchUrl = 'https://discoveryengine.googleapis.com/v1alpha/projects/your-project-id/locations/global/collections/default_collection/engines/your-engine-id/servingConfigs/default_config:search';
  
  // TODO: Replace with your actual Vertex AI Search configuration
  static const String _apiKey = 'YOUR_VERTEX_AI_API_KEY';

  /// Retrieves contextual data from Vertex AI Search
  static Future<RAGContext> retrieveContext(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_vertexAiSearchUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'query': query,
          'pageSize': 5,
          'contentSearchSpec': {
            'snippetSpec': {'maxSnippetCount': 3},
            'summarySpec': {
              'summaryResultCount': 5,
              'ignoreAdversarialQuery': true,
              'ignoreNonSummarySeekingQuery': true,
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSearchResponse(query, data);
      } else {
        throw Exception('Vertex AI Search error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockContext(query);
    }
  }

  static RAGContext _parseSearchResponse(String query, Map<String, dynamic> data) {
    final sources = <Map<String, dynamic>>[];
    final snippets = <String>[];

    if (data['results'] != null) {
      for (final result in data['results']) {
        sources.add({
          'title': result['document']['derivedStructData']['title'] ?? 'Unknown',
          'url': result['document']['derivedStructData']['link'] ?? '',
          'snippet': result['document']['derivedStructData']['snippets']?.isNotEmpty == true
              ? result['document']['derivedStructData']['snippets'][0]['snippet'] ?? ''
              : '',
        });
        
        if (result['document']['derivedStructData']['snippets']?.isNotEmpty == true) {
          snippets.add(result['document']['derivedStructData']['snippets'][0]['snippet'] ?? '');
        }
      }
    }

    final context = snippets.isNotEmpty ? snippets.join('\n\n') : 'No specific data found for this query.';

    return RAGContext(
      query: query,
      sources: sources,
      context: context,
      retrievedAt: DateTime.now(),
    );
  }

  static RAGContext _getMockContext(String query) {
    // Mock Malaysian economic data for demonstration
    final mockData = {
      'average m40 transport spend': {
        'context': 'Average monthly transport expenditure for M40 households in Malaysia is approximately RM400-600, with urban areas showing higher spending due to longer commute distances and reliance on private vehicles.',
        'sources': [
          {'title': 'DOSM Household Expenditure Survey 2023', 'url': 'https://www.dosm.gov.my'},
          {'title': 'Malaysian Transportation Statistics', 'url': 'https://www.mot.gov.my'},
        ],
      },
      'b40 income statistics': {
        'context': 'B40 households in Malaysia have median monthly income of RM3,000-4,849, with 60% of income spent on basic necessities including housing, food, and transportation.',
        'sources': [
          {'title': 'B40 Economic Outlook Report', 'url': 'https://www.epu.gov.my'},
          {'title': 'Household Income and Poverty Survey', 'url': 'https://www.dosm.gov.my'},
        ],
      },
      'inflation impact malaysia': {
        'context': 'Malaysian inflation rate averaged 3.5% in 2023, with food and transport prices being the main contributors. B40 households experience higher effective inflation due to larger proportion of income spent on essentials.',
        'sources': [
          {'title': 'Bank Negara Inflation Report', 'url': 'https://www.bnm.gov.my'},
          {'title': 'CPI Statistics Malaysia', 'url': 'https://www.dosm.gov.my'},
        ],
      },
      'digital adoption rates': {
        'context': 'Digital adoption among Malaysians varies by income tier: T20 (85-90%), M40 (70-80%), B40 (40-60%). Rural areas show 20-30% lower adoption rates compared to urban areas.',
        'sources': [
          {'title': 'MDEC Digital Adoption Survey', 'url': 'https://www.mdec.gov.my'},
          {'title': 'Malaysia Digital Economy Blueprint', 'url': 'https://www.mdec.gov.my'},
        ],
      },
    };

    final queryLower = query.toLowerCase();
    String context = 'No specific data found for this query.';
    List<Map<String, dynamic>> sources = [];

    for (final key in mockData.keys) {
      if (queryLower.contains(key.toLowerCase()) || key.toLowerCase().contains(queryLower)) {
        context = mockData[key]!['context'] as String;
        sources = mockData[key]!['sources'] as List<Map<String, dynamic>>;
        break;
      }
    }

    return RAGContext(
      query: query,
      sources: sources,
      context: context,
      retrievedAt: DateTime.now(),
    );
  }

  /// Injects RAG context into agent prompts
  static String injectContextIntoPrompt(String basePrompt, RAGContext ragContext) {
    return '''
$basePrompt

CONTEXTUAL DATA (Malaysian Economic Indicators):
${ragContext.context}

SOURCES:
${ragContext.sources.map((s) => "- ${s['title']}: ${s['url']}").join('\n')}

Use this contextual data to make more accurate and realistic decisions based on current Malaysian economic conditions.
''';
  }

  /// Generates contextual queries based on agent profile and current situation
  static List<String> generateContextualQueries(AgentDNA agent, List<SubLayer> subLayers) {
    final queries = <String>[];

    // Income tier specific queries
    switch (agent.incomeTier) {
      case IncomeTier.B40:
        queries.add('B40 household expenditure patterns Malaysia');
        queries.add('subsidy programs for low income Malaysia');
        break;
      case IncomeTier.M40:
        queries.add('M40 middle class economic challenges Malaysia');
        queries.add('inflation impact on middle income Malaysia');
        break;
      case IncomeTier.T20:
        queries.add('T20 investment patterns Malaysia');
        queries.add('high income tax planning Malaysia');
        break;
    }

    // Occupation specific queries
    switch (agent.occupationType) {
      case OccupationType.gigWorker:
        queries.add('gig economy income Malaysia');
        queries.add('freelancer financial stability Malaysia');
        break;
      case OccupationType.smeOwner:
        queries.add('SME business challenges Malaysia');
        queries.add('small business loan access Malaysia');
        break;
      case OccupationType.civilServant:
        queries.add('civil servant salary Malaysia');
        queries.add('government employee benefits Malaysia');
        break;
      case OccupationType.salariedCorporate:
        queries.add('private sector employment Malaysia');
        queries.add('corporate salary trends Malaysia');
        break;
      case OccupationType.unemployed:
        queries.add('unemployment benefits Malaysia');
        queries.add('job training programs Malaysia');
        break;
    }

    // Location specific queries
    switch (agent.locationMatrix) {
      case LocationMatrix.urban:
        queries.add('urban cost of living Malaysia');
        queries.add('city transportation costs Malaysia');
        break;
      case LocationMatrix.rural:
        queries.add('rural development Malaysia');
        queries.add('agricultural subsidies Malaysia');
        break;
      case LocationMatrix.suburban:
        queries.add('suburban housing Malaysia');
        queries.add('commuting patterns Malaysia');
        break;
    }

    // Sub-layer specific queries
    for (final subLayer in subLayers) {
      if (agent.subLayerMatches(subLayer)) {
        switch (subLayer.parentKnob) {
          case UniversalKnobType.operationalExpenseIndex:
            queries.add('inflation impact on ${agent.incomeTier.name} Malaysia');
            break;
          case UniversalKnobType.disposableIncomeDelta:
            queries.add('disposable income trends ${agent.incomeTier.name} Malaysia');
            break;
          case UniversalKnobType.capitalAccessPressure:
            queries.add('interest rates impact Malaysia');
            queries.add('loan access ${agent.incomeTier.name} Malaysia');
            break;
          case UniversalKnobType.systemicFriction:
            queries.add('government services efficiency Malaysia');
            break;
          case UniversalKnobType.socialEquityWeight:
            queries.add('income inequality Malaysia');
            queries.add('Gini coefficient Malaysia');
            break;
          case UniversalKnobType.systemicTrustBaseline:
            queries.add('social trust Malaysia');
            break;
          case UniversalKnobType.futureMobilityIndex:
            queries.add('social mobility Malaysia');
            break;
          case UniversalKnobType.ecologicalResourcePressure:
            queries.add('environmental policy impact Malaysia');
            break;
        }
      }
    }

    return queries.toSet().toList(); // Remove duplicates
  }
}

// Extension method to check if agent matches sub-layer demographics
extension AgentDNAExtension on AgentDNA {
  bool subLayerMatches(SubLayer subLayer) {
    return subLayer.targetDemographics.contains(incomeTier.name) ||
           subLayer.targetDemographics.contains(occupationType.name) ||
           subLayer.targetDemographics.contains(locationMatrix.name);
  }
}
