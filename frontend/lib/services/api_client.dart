/// api_client.dart — PolicyIQ HTTP + SSE Client
///
/// Provides:
///   - [validatePolicy]  POST /validate-policy  (Contract Pre-A → Pre-B)
///   - [simulateStream]  POST /simulate          (Contract A → SSE tick/complete events)
///
/// Also exposes [SimulationState] — a ChangeNotifier that the Provider tree
/// uses to drive UI rebuilds.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/contracts.dart';

// ─── Configuration ────────────────────────────────────────────────────────────

/// Base URL of the PolicyIQ FastAPI backend.
/// Override this for different environments.
const String _kApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

// ─── ApiClient ────────────────────────────────────────────────────────────────

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? _kApiBaseUrl,
        _httpClient = httpClient ?? http.Client();

  // ── Contract Pre-A → Pre-B ─────────────────────────────────────────────────

  /// Sends a raw policy text to the Gatekeeper and returns the validation result.
  ///
  /// Throws [ApiException] on non-2xx responses.
  Future<ValidatePolicyResponse> validatePolicy(String rawPolicyText) async {
    final uri = Uri.parse('$baseUrl/validate-policy');
    final request = ValidatePolicyRequest(rawPolicyText: rawPolicyText);

    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return ValidatePolicyResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ── Contract A → SSE (tick / complete / error events) ─────────────────────

  /// Initiates the simulation and returns a [Stream] of SSE events.
  ///
  /// Each emitted [SseEvent] has:
  ///   - [SseEvent.type] — `'tick'`, `'complete'`, or `'error'`
  ///   - [SseEvent.data] — JSON-decoded payload as Map<String, dynamic>
  ///
  /// The stream closes automatically after the `'complete'` or `'error'` event.
  Stream<SseEvent> simulateStream(SimulateRequest request) async* {
    final uri = Uri.parse('$baseUrl/simulate');

    // POST the simulation request body; the server responds with
    // Content-Type: text/event-stream.
    final httpRequest = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode(request.toJson());

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _httpClient.send(httpRequest);
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw ApiException(streamedResponse.statusCode, body);
    }

    // Parse the raw SSE byte stream into typed events.
    String eventType = 'message';
    final StringBuffer dataBuffer = StringBuffer();

    await for (final chunk
        in streamedResponse.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          dataBuffer.write(line.substring(5).trim());
        } else if (line.isEmpty && dataBuffer.isNotEmpty) {
          // Blank line = end of SSE event
          final rawData = dataBuffer.toString();
          dataBuffer.clear();

          Map<String, dynamic> payload;
          try {
            payload = jsonDecode(rawData) as Map<String, dynamic>;
          } catch (_) {
            payload = {'raw': rawData};
          }

          yield SseEvent(type: eventType, data: payload);

          if (eventType == 'complete' || eventType == 'error') return;
          eventType = 'message'; // Reset for next event
        }
      }
    }
  }

  void dispose() => _httpClient.close();
}

// ─── SSE Event ────────────────────────────────────────────────────────────────

class SseEvent {
  final String type;
  final Map<String, dynamic> data;

  const SseEvent({required this.type, required this.data});

  @override
  String toString() => 'SseEvent(type: $type, data: $data)';
}

// ─── ApiException ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─── SimulationState (ChangeNotifier / Provider) ─────────────────────────────

/// Shared state for the simulation UI.
/// Consumed by DashboardScreen, GatekeeperUI, ControlPanel, and AnomalyHunter.
class SimulationState extends ChangeNotifier {
  // ── Input state ───────────────────────────────────────────────────────────
  String policyText = '';
  int simulationTicks = 4;
  int agentCount = 5;
  KnobOverrides knobOverrides = const KnobOverrides();

  // ── Validation state ──────────────────────────────────────────────────────
  ValidatePolicyResponse? validationResult;
  bool isValidating = false;
  String? validationError;

  // ── Simulation state ──────────────────────────────────────────────────────
  bool isSimulating = false;
  List<TickSummary> ticks = [];
  SimulateResponse? finalResult;
  String? simulationError;

  // ── Helpers ───────────────────────────────────────────────────────────────

  void setValidating(bool value) {
    isValidating = value;
    notifyListeners();
  }

  void setValidationResult(ValidatePolicyResponse? result, {String? error}) {
    validationResult = result;
    validationError = error;
    isValidating = false;
    notifyListeners();
  }

  void setSimulating(bool value) {
    if (value) {
      ticks = [];
      finalResult = null;
      simulationError = null;
    }
    isSimulating = value;
    notifyListeners();
  }

  void addTick(TickSummary tick) {
    ticks = [...ticks, tick];
    notifyListeners();
  }

  void setFinalResult(SimulateResponse result) {
    finalResult = result;
    isSimulating = false;
    notifyListeners();
  }

  void setSimulationError(String error) {
    simulationError = error;
    isSimulating = false;
    notifyListeners();
  }

  void updateKnobOverrides(KnobOverrides overrides) {
    knobOverrides = overrides;
    notifyListeners();
  }
}
