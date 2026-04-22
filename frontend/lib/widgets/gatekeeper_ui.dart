/// gatekeeper_ui.dart — Policy input box with validation state display.
///
/// Handles:
///   - Free-text policy input
///   - Calling POST /validate-policy on submit
///   - Showing rejection reason and refined option chips

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';

class GatekeeperUI extends StatefulWidget {
  const GatekeeperUI({super.key});

  @override
  State<GatekeeperUI> createState() => _GatekeeperUIState();
}

class _GatekeeperUIState extends State<GatekeeperUI> {
  final _controller = TextEditingController();

  Future<void> _validate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final state = context.read<SimulationState>();
    final client = context.read<ApiClient>();
    state.policyText = text;
    state.setValidating(true);

    try {
      final result = await client.validatePolicy(text);
      state.setValidationResult(result);
    } catch (e) {
      state.setValidationResult(null, error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SimulationState>();
    final result = state.validationResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Policy Input',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a Malaysian government policy…',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0D0D1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: state.isValidating ? null : _validate,
            child: Text(state.isValidating ? 'Validating…' : 'Validate Policy'),
          ),
        ),

        if (result != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result.isValid
                  ? const Color(0xFF48CFAD).withOpacity(0.1)
                  : const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.isValid ? const Color(0xFF48CFAD) : const Color(0xFFFF6B6B),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(result.isValid ? Icons.check_circle : Icons.cancel,
                      color: result.isValid ? const Color(0xFF48CFAD) : const Color(0xFFFF6B6B),
                      size: 16),
                  const SizedBox(width: 6),
                  Text(result.isValid ? 'Policy Accepted' : 'Policy Rejected',
                      style: TextStyle(
                          color: result.isValid ? const Color(0xFF48CFAD) : const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
                if (result.rejectionReason != null) ...[
                  const SizedBox(height: 6),
                  Text(result.rejectionReason!,
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
                if (result.refinedOptions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Refined options:',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  ...result.refinedOptions.map((opt) => GestureDetector(
                    onTap: () {
                      _controller.text = opt;
                      context.read<SimulationState>().policyText = opt;
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(opt,
                          style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 11)),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],

        if (state.validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Error: ${state.validationError}',
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11)),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
