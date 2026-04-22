/// control_panel.dart — 8-Knob manual override sliders.
///
/// Allows the user to manually set any of the 8 Universal Knobs before
/// simulation. Null (unset) knobs are determined by the AI decomposition.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contracts.dart';
import '../services/api_client.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  bool _expanded = false;

  // Local slider state: null = AI-determined
  final Map<String, double?> _overrides = {
    'disposable_income_delta': null,
    'operational_expense_index': null,
    'capital_access_pressure': null,
    'systemic_friction': null,
    'social_equity_weight': null,
    'systemic_trust_baseline': null,
    'future_mobility_index': null,
    'ecological_pressure': null,
  };

  static const _labels = {
    'disposable_income_delta': 'Disposable Income Δ',
    'operational_expense_index': 'Operational Expense Index',
    'capital_access_pressure': 'Capital Access Pressure',
    'systemic_friction': 'Systemic Friction',
    'social_equity_weight': 'Social Equity Weight',
    'systemic_trust_baseline': 'Systemic Trust Baseline',
    'future_mobility_index': 'Future Mobility Index',
    'ecological_pressure': 'Ecological Pressure',
  };

  void _applyOverrides() {
    context.read<SimulationState>().updateKnobOverrides(KnobOverrides(
      disposableIncomeDelta: _overrides['disposable_income_delta'],
      operationalExpenseIndex: _overrides['operational_expense_index'],
      capitalAccessPressure: _overrides['capital_access_pressure'],
      systemicFriction: _overrides['systemic_friction'],
      socialEquityWeight: _overrides['social_equity_weight'],
      systemicTrustBaseline: _overrides['systemic_trust_baseline'],
      futureMobilityIndex: _overrides['future_mobility_index'],
      ecologicalPressure: _overrides['ecological_pressure'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: const Text('Control Panel (8 Knobs)',
                style: TextStyle(color: Colors.white70,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: const Text('Override before simulation',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white38),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: _overrides.keys.map((key) {
                  final val = _overrides[key];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_labels[key] ?? key,
                              style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          GestureDetector(
                            onTap: () => setState(() {
                              _overrides[key] = null;
                              _applyOverrides();
                            }),
                            child: Text(
                              val == null ? 'AUTO' : val.toStringAsFixed(2),
                              style: TextStyle(
                                  color: val == null
                                      ? Colors.white38
                                      : const Color(0xFF6C63FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: val ?? 0.0,
                        min: -1.0,
                        max: 1.0,
                        divisions: 40,
                        activeColor: val == null
                            ? Colors.white12
                            : const Color(0xFF6C63FF),
                        onChanged: (v) => setState(() {
                          _overrides[key] = v;
                          _applyOverrides();
                        }),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
