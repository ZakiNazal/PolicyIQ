import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/system_models.dart';
import '../widgets/control/stability_meter.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen>
    with TickerProviderStateMixin {
  late List<UniversalKnob> _knobs;
  bool _overrideActive = false;
  String? _activeKnobId;
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  // Presets for the 8 Universal Knobs
  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'EQUILIBRIUM',
      'description': 'Balanced baseline state',
      'color': AppTheme.accentGreen,
      'values': <UniversalKnobType, double>{
        UniversalKnobType.disposableIncomeDelta: 0.0,
        UniversalKnobType.operationalExpenseIndex: 0.0,
        UniversalKnobType.capitalAccessPressure: 0.0,
        UniversalKnobType.systemicFriction: 0.0,
        UniversalKnobType.socialEquityWeight: 0.0,
        UniversalKnobType.systemicTrustBaseline: 0.0,
        UniversalKnobType.futureMobilityIndex: 0.0,
        UniversalKnobType.ecologicalResourcePressure: 0.0,
      },
    },
    {
      'name': 'ECONOMIC STRESS',
      'description': 'High financial pressure',
      'color': AppTheme.accentRed,
      'values': <UniversalKnobType, double>{
        UniversalKnobType.disposableIncomeDelta: -0.8,
        UniversalKnobType.operationalExpenseIndex: 0.7,
        UniversalKnobType.capitalAccessPressure: 0.6,
        UniversalKnobType.systemicFriction: 0.3,
        UniversalKnobType.socialEquityWeight: -0.4,
        UniversalKnobType.systemicTrustBaseline: -0.2,
        UniversalKnobType.futureMobilityIndex: -0.3,
        UniversalKnobType.ecologicalResourcePressure: 0.2,
      },
    },
    {
      'name': 'SOCIAL COHESION',
      'description': 'High trust and equity',
      'color': AppTheme.accentCyan,
      'values': <UniversalKnobType, double>{
        UniversalKnobType.disposableIncomeDelta: 0.3,
        UniversalKnobType.operationalExpenseIndex: -0.2,
        UniversalKnobType.capitalAccessPressure: -0.1,
        UniversalKnobType.systemicFriction: -0.6,
        UniversalKnobType.socialEquityWeight: 0.8,
        UniversalKnobType.systemicTrustBaseline: 0.7,
        UniversalKnobType.futureMobilityIndex: 0.6,
        UniversalKnobType.ecologicalResourcePressure: 0.1,
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
    _scanCtrl.repeat(reverse: true);
    _knobs = _initializeUniversalKnobs();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  List<UniversalKnob> _initializeUniversalKnobs() {
    return [
      UniversalKnob(
        type: UniversalKnobType.disposableIncomeDelta,
        label: 'Disposable Income',
        description: 'Direct cash flow changes for citizens',
        value: 0.0,
        accentColor: const Color(0xFF00BCD4),
      ),
      UniversalKnob(
        type: UniversalKnobType.operationalExpenseIndex,
        label: 'Operational Expenses',
        description: 'Cost of living, inflation, subsidy cuts',
        value: 0.0,
        accentColor: const Color(0xFF4CAF50),
      ),
      UniversalKnob(
        type: UniversalKnobType.capitalAccessPressure,
        label: 'Capital Access',
        description: 'Debt, borrowing stress, OPR changes',
        value: 0.0,
        accentColor: const Color(0xFFFF9800),
      ),
      UniversalKnob(
        type: UniversalKnobType.systemicFriction,
        label: 'Systemic Friction',
        description: 'Time poverty, administrative red tape',
        value: 0.0,
        accentColor: const Color(0xFFF44336),
      ),
      UniversalKnob(
        type: UniversalKnobType.socialEquityWeight,
        label: 'Social Equity',
        description: 'Perception of fairness, Gini impact',
        value: 0.0,
        accentColor: const Color(0xFF9C27B0),
      ),
      UniversalKnob(
        type: UniversalKnobType.systemicTrustBaseline,
        label: 'Systemic Trust',
        description: 'Social contract strength',
        value: 0.0,
        accentColor: const Color(0xFF2196F3),
      ),
      UniversalKnob(
        type: UniversalKnobType.futureMobilityIndex,
        label: 'Future Mobility',
        description: 'Upskilling, class mobility opportunities',
        value: 0.0,
        accentColor: const Color(0xFF009688),
      ),
      UniversalKnob(
        type: UniversalKnobType.ecologicalResourcePressure,
        label: 'Ecological Pressure',
        description: 'Sustainability metrics',
        value: 0.0,
        accentColor: const Color(0xFF795548),
      ),
    ];
  }

  double _getSystemStress() {
    // Calculate overall system stress based on knob values
    double stress = 0.0;
    for (final knob in _knobs) {
      stress += knob.value.abs();
    }
    return (stress / _knobs.length).clamp(0.0, 1.0);
  }

  void _applyPreset(Map<String, dynamic> preset) {
    final values = preset['values'] as Map<UniversalKnobType, double>;
    setState(() {
      for (int i = 0; i < _knobs.length; i++) {
        _knobs[i].value = values[_knobs[i].type] ?? 0.0;
      }
      _overrideActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stress = _getSystemStress();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildTopBar(stress),
          Expanded(
            child: Row(
              children: [
                _buildKnobPanel(),
                _buildRadarPanel(stress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double stress) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _buildBreadcrumb('Control Panel', true),
          const Icon(Icons.chevron_right, size: 12, color: AppTheme.textMuted),
          _buildBreadcrumb('Universal Knobs', false),
          const Spacer(),
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (context, _) {
              final scanColor = stress > 0.6
                  ? AppTheme.accentRed
                  : stress > 0.35
                      ? AppTheme.accentAmber
                      : AppTheme.accentGreen;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scanColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: scanColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: scanColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stress > 0.6
                          ? 'HIGH STRESS'
                          : stress > 0.35
                              ? 'MODERATE'
                              : 'STABLE',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 8,
                        color: scanColor,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 10,
        color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildKnobPanel() {
    return Expanded(
      flex: 2,
      child: GlassPanel(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  const SectionLabel('Universal Knobs'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '8 parameters governing societal simulation',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: 'Override policy effects with manual knob adjustments',
                    child: GestureDetector(
                      onTap: () => setState(() => _overrideActive = !_overrideActive),
                      child: Row(
                        children: [
                          Icon(
                            _overrideActive ? Icons.lock_open : Icons.lock,
                            size: 14,
                            color: _overrideActive
                                ? AppTheme.accentAmber
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _overrideActive ? 'OVERRIDE ON' : 'OVERRIDE OFF',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              color: _overrideActive
                                  ? AppTheme.accentAmber
                                  : AppTheme.textMuted,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _knobs.length,
                itemBuilder: (context, i) {
                  final knob = _knobs[i];
                  return GestureDetector(
                    onTap: () => setState(() => _activeKnobId = knob.type.name),
                    child: _buildUniversalKnobCard(knob, _activeKnobId == knob.type.name),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Presets'),
                  const SizedBox(height: 12),
                  ..._presets.map((preset) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _applyPreset(preset),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (preset['color'] as Color).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (preset['color'] as Color).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: preset['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset['name'] as String,
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: preset['color'] as Color,
                                    ),
                                  ),
                                  Text(
                                    preset['description'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 9,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversalKnobCard(UniversalKnob knob, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.surfaceElevated : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? knob.accentColor.withOpacity(0.5) : AppTheme.border,
          width: isActive ? 2 : 1,
        ),
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
                  color: knob.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  knob.label,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? knob.accentColor : AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(knob.value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: knob.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            knob.description,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: knob.accentColor,
              inactiveTrackColor: knob.accentColor.withOpacity(0.2),
              thumbColor: knob.accentColor,
              overlayColor: knob.accentColor.withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 2,
            ),
            child: Slider(
              value: knob.value,
              min: -1.0,
              max: 1.0,
              onChanged: (value) {
                setState(() => knob.value = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarPanel(double stress) {
    return Expanded(
      child: GlassPanel(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SectionLabel('System Stability'),
                  const SizedBox(height: 16),
                  _buildStabilityMeter(stress),
                  const SizedBox(height: 20),
                  _buildSystemMetrics(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStabilityMeter(double stress) {
    return StabilityMeter(stress: stress);
  }

  Widget _buildSystemMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Knob Distribution',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._knobs.map((knob) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: knob.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  knob.label,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (knob.value + 1.0) / 2.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: knob.value > 0 ? knob.accentColor : knob.accentColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                knob.value > 0 ? '+' : '',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: knob.value > 0 ? knob.accentColor : AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                (knob.value.abs() * 100).toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: knob.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;

  const GlassPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const SectionLabel(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? AppTheme.textPrimary,
        letterSpacing: 1.2,
      ),
    );
  }
}
