import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/system_models.dart';
import '../services/gatekeeper_service.dart';
import '../services/decomposition_service.dart';

enum InputValidationState { idle, typing, validating, vague, refined, ready }

class GatekeeperScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigate;

  const GatekeeperScreen({super.key, this.onNavigate});

  @override
  State<GatekeeperScreen> createState() => _GatekeeperScreenState();
}

class _GatekeeperScreenState extends State<GatekeeperScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  InputValidationState _state = InputValidationState.idle;
  String _selectedRefinement = '';
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;
  
  // New policy validation state
  PolicyValidationResult? _validationResult;
  DecompositionResult? _decompositionResult;
  PolicyInput? _currentPolicy;
  bool _isValidating = false;

  final List<Map<String, String>> _recentPolicies = [
    {'text': 'What happens if we cut welfare by half?', 'status': 'VAGUE → REFINED'},
    {'text': 'Universal basic income pilot program', 'status': 'VALIDATED'},
    {'text': 'Carbon tax for manufacturing sector', 'status': 'VALIDATED'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _analyzeInput() async {
    if (_controller.text.isEmpty) return;
    setState(() {
      _state = InputValidationState.validating;
      _isValidating = true;
      _validationResult = null;
      _decompositionResult = null;
    });

    try {
      // Step 1: Validate policy with Gatekeeper
      final validation = await GatekeeperService.validatePolicy(_controller.text);
      
      if (!mounted) return;
      
      setState(() {
        _validationResult = validation;
        _isValidating = false;
      });

      if (validation.isValid) {
        // Step 2: Decompose policy into Sub-Layers
        final decomposition = await DecompositionService.decomposePolicy(
          _controller.text,
          validation.economicLever,
          validation.targetGroups,
        );
        
        if (!mounted) return;
        
        setState(() {
          _decompositionResult = decomposition;
          _state = InputValidationState.ready;
        });
        
        // Create policy input object
        _currentPolicy = PolicyInput(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'User Policy',
          description: _controller.text,
          policyText: _controller.text,
          createdAt: DateTime.now(),
          validationResults: validation.toJson(),
          refinedOptions: validation.refinedOptions,
        );
      } else {
        setState(() {
          _state = InputValidationState.vague;
        });
      }
      
      _slideCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _state = InputValidationState.idle;
      });
    }
  }

  void _selectRefinement(String label) {
    setState(() {
      _selectedRefinement = label;
      _state = InputValidationState.refined;
      _controller.text = label;
    });
  }

  void _goToControlPanel() => widget.onNavigate?.call(1);
  void _goToMacroAnalytics() => widget.onNavigate?.call(2);

  Color get _stateColor {
    switch (_state) {
      case InputValidationState.idle:
        return AppTheme.textMuted;
      case InputValidationState.typing:
        return AppTheme.accentCyan;
      case InputValidationState.validating:
        return AppTheme.accentAmber;
      case InputValidationState.vague:
        return AppTheme.accentRed;
      case InputValidationState.refined:
      case InputValidationState.ready:
        return AppTheme.accentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(),
                  const SizedBox(height: 32),
                  if (_state == InputValidationState.vague)
                    SlideTransition(
                      position: _slideAnim,
                      child: _buildRefinementOptions(),
                    ),
                  if (_state == InputValidationState.ready ||
                      _state == InputValidationState.refined)
                    SlideTransition(
                      position: _slideAnim,
                      child: _buildSuccessPanel(),
                    ),
                  const SizedBox(height: 32),
                  _buildRecentPolicies(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.policy,
              color: AppTheme.accentCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POLICY INPUT',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Gatekeeper Validation System',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildStatusBubble('AI VALIDATION', AppTheme.accentCyan),
        ],
      ),
    );
  }

  Widget _buildStatusBubble(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 10,
          color: color,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('POLICY TEXT'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _stateColor.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 6,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter Malaysian government policy text for simulation...',
              hintStyle: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: (value) {
              if (_state == InputValidationState.idle) {
                setState(() => _state = InputValidationState.typing);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_isValidating)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(width: 12),
            Text(
              _isValidating ? 'Validating with AI...' : _getValidationMessage(),
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: _stateColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _controller.text.isNotEmpty && !_isValidating ? _analyzeInput : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _stateColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                _isValidating ? 'ANALYZING...' : 'VALIDATE POLICY',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getValidationMessage() {
    switch (_state) {
      case InputValidationState.idle:
        return 'Enter policy text to begin validation';
      case InputValidationState.typing:
        return 'Type your policy and click validate';
      case InputValidationState.validating:
        return 'AI is analyzing your policy...';
      case InputValidationState.vague:
        return 'Policy needs refinement';
      case InputValidationState.refined:
      case InputValidationState.ready:
        return 'Policy is ready for simulation';
    }
  }

  Widget _buildRefinementOptions() {
    if (_validationResult == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              _validationResult!.isValid ? Icons.check_circle : Icons.warning,
              size: 12,
              color: _validationResult!.isValid ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
            const SizedBox(width: 8),
            SectionLabel(
              _validationResult!.isValid ? 'POLICY VALID' : 'POLICY REJECTED',
              color: _validationResult!.isValid ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _validationResult!.isValid 
                ? AppTheme.accentGreen.withOpacity(0.05)
                : AppTheme.accentRed.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _validationResult!.isValid 
                  ? AppTheme.accentGreen.withOpacity(0.3)
                  : AppTheme.accentRed.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _validationResult!.isValid ? 'Policy is simulation-ready' : 'Policy needs refinement',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _validationResult!.isValid ? AppTheme.accentGreen : AppTheme.accentRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _validationResult!.reasoning,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (!_validationResult!.isValid && _validationResult!.refinedOptions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'RECOMMENDED OPTIONS:',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ..._validationResult!.refinedOptions.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => _selectRefinement(option),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )),
              ],
              if (_validationResult!.isValid && _decompositionResult != null) ...[
                const SizedBox(height: 16),
                _buildDecompositionResults(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecompositionResults() {
    if (_decompositionResult == null || !_decompositionResult!.success) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.layers, size: 12, color: AppTheme.accentCyan),
            SizedBox(width: 8),
            SectionLabel('DYNAMIC DECOMPOSITION', color: AppTheme.accentCyan),
          ],
        ),
        const SizedBox(height: 8),
        ..._decompositionResult!.subLayers.map((subLayer) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: subLayer.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subLayer.name,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                      '×${subLayer.impactMultiplier.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subLayer.description,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: subLayer.targetDemographics.map((demo) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    demo,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSuccessPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 16),
              const SizedBox(width: 8),
              const Text(
                'POLICY VALIDATED',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'READY FOR SIMULATION',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your policy has been validated by the Gatekeeper AI and decomposed into simulation-ready Sub-Layers. You can now proceed to the Universal Knobs to configure the simulation parameters.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _goToControlPanel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'CONFIGURE KNOBS',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToMacroAnalytics,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGreen,
                    side: const BorderSide(color: AppTheme.accentGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'VIEW ANALYTICS',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPolicies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('RECENT POLICIES'),
        const SizedBox(height: 12),
        ..._recentPolicies.map((policy) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  policy['text']!,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                ),
                child: Text(
                  policy['status']!,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.accentCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
