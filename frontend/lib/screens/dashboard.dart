/// dashboard.dart — PolicyIQ Main Dashboard Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../models/contracts.dart';
import '../widgets/gatekeeper_ui.dart';
import '../widgets/control_panel.dart';
import '../widgets/anomaly_hunter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _runSimulation(BuildContext context) async {
    final state = context.read<SimulationState>();
    final client = context.read<ApiClient>();
    if (state.policyText.isEmpty) return;
    state.setSimulating(true);

    final request = SimulateRequest(
      policyText: state.policyText,
      simulationTicks: state.simulationTicks,
      agentCount: state.agentCount,
      knobOverrides: state.knobOverrides,
    );

    try {
      await for (final event in client.simulateStream(request)) {
        switch (event.type) {
          case 'tick':
            state.addTick(TickSummary.fromJson(event.data));
          case 'complete':
            state.setFinalResult(SimulateResponse.fromJson(event.data));
          case 'error':
            state.setSimulationError(event.data['detail']?.toString() ?? 'Unknown error');
        }
      }
    } catch (e) {
      state.setSimulationError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SimulationState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13132A),
        title: const Text('PolicyIQ — Policy Stress-Testing Engine',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          if (state.isSimulating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          SizedBox(
            width: 320,
            child: Container(
              color: const Color(0xFF13132A),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const GatekeeperUI(),
                  const SizedBox(height: 16),
                  const ControlPanel(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.isSimulating || state.validationResult?.isValid != true
                          ? null
                          : () => _runSimulation(context),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(state.isSimulating ? 'Simulating…' : 'Run Simulation'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: state.ticks.isEmpty
                  ? const Center(child: Text('Enter a policy to begin.',
                      style: TextStyle(color: Colors.white54)))
                  : ListView(
                      children: [
                        if (state.finalResult != null) ...[
                          Text('Sentiment Shift: ${state.finalResult!.macroSummary.overallSentimentShift}',
                              style: const TextStyle(color: Color(0xFF48CFAD), fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Inequality Δ: ${state.finalResult!.macroSummary.inequalityDelta}',
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                        ],
                        ...state.ticks.map((t) => ListTile(
                          leading: CircleAvatar(child: Text('T${t.tickId}')),
                          title: Text('Tick ${t.tickId} — avg sentiment: ${t.averageSentiment.toStringAsFixed(3)}',
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${t.agentActions.length} agents',
                              style: const TextStyle(color: Colors.white54)),
                        )),
                        if (state.finalResult?.anomalies.isNotEmpty == true)
                          AnomalyHunter(anomalies: state.finalResult!.anomalies),
                        if (state.finalResult?.aiPolicyRecommendation.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(state.finalResult!.aiPolicyRecommendation,
                                style: const TextStyle(color: Colors.white70)),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
