import '../models/sim_models.dart';

class SimulationEngine {
  final List<SimKnob> _knobs;
  int _cycle = 0;
  int _citizens = 1247;
  int _anomalies = 3;
  DateTime _currentTime = DateTime(2047, 3, 14);
  double _systemStress = 0.6;

  SimulationEngine(this._knobs);

  List<SimKnob> get knobs => List.unmodifiable(_knobs);
  int get cycle => _cycle;
  int get citizens => _citizens;
  int get anomalies => _anomalies;
  DateTime get currentTime => _currentTime;
  double get systemStress => _systemStress;

  SimKnob? _findKnob(String id) {
    for (final k in _knobs) {
      if (k.id == id) return k;
    }
    return null;
  }

  double _knobValue(String id, {required double fallback}) {
    return _findKnob(id)?.value ?? fallback;
  }

  void updateKnobValue(String knobId, double value) {
    final knob = _findKnob(knobId);
    if (knob == null) return;
    knob.value = value;
    _recalculateSystemState();
  }

  void nextCycle() {
    _cycle++;
    _recalculateSystemState();
    _updateDemographics();
    _detectAnomalies();
  }

  void _recalculateSystemState() {
    // Calculate system stress based on knob values
    double stress = 0.0;
    for (final knob in _knobs) {
      final denom = (knob.max - knob.min);
      final normalizedValue =
          denom == 0 ? 0.0 : (knob.value - knob.min) / denom;
      
      // Different weights for different parameters
      switch (knob.id) {
        case 'tax_rate':
          stress += normalizedValue * 0.15;
          break;
        case 'welfare':
          stress += (1 - normalizedValue) * 0.12;
          break;
        case 'surveillance':
          stress += normalizedValue * 0.18;
          break;
        case 'media_control':
          stress += normalizedValue * 0.14;
          break;
        case 'innovation':
          stress += (1 - normalizedValue) * 0.10;
          break;
        case 'migration':
          stress += normalizedValue * 0.08;
          break;
        case 'resource_scarcity':
          stress += normalizedValue * 0.15;
          break;
        case 'trust_index':
          stress += (1 - normalizedValue) * 0.08;
          break;
      }
    }
    
    _systemStress = stress.clamp(0.0, 1.0);
  }

  void _updateDemographics() {
    // Update citizen count based on system parameters
    final migrationFactor = (_knobValue('migration', fallback: 50) - 50) / 50;
    final welfareFactor = _knobValue('welfare', fallback: 50) / 100;
    
    final growthRate = (migrationFactor * 0.02) + (welfareFactor * 0.01) - 0.005;
    _citizens = (_citizens * (1 + growthRate)).round();
    _citizens = _citizens.clamp(100, 10000);
  }

  void _detectAnomalies() {
    // Detect anomalies based on system stress and parameter combinations
    final surveillance = _knobValue('surveillance', fallback: 50);
    final mediaControl = _knobValue('media_control', fallback: 50);
    final trust = _knobValue('trust_index', fallback: 50);
    
    _anomalies = 0;
    
    // High surveillance + low trust = more anomalies
    if (surveillance > 70 && trust < 30) {
      _anomalies += 2;
    }
    
    // High media control + low welfare = more anomalies  
    if (mediaControl > 70 && _knobValue('welfare', fallback: 50) < 30) {
      _anomalies += 2;
    }
    
    // Random chance based on system stress
    if (_systemStress > 0.8) {
      _anomalies += 3;
    } else if (_systemStress > 0.6) {
      _anomalies += 1;
    }
    
    _anomalies = _anomalies.clamp(0, 10);
  }

  void advanceTime() {
    _currentTime = _currentTime.add(const Duration(days: 1));
  }

  Map<String, dynamic> getSystemMetrics() {
    return {
      'cycle': _cycle,
      'citizens': _citizens,
      'anomalies': _anomalies,
      'time': _currentTime,
      'stress': _systemStress,
      'stability': _getStabilityLevel(),
    };
  }

  String _getStabilityLevel() {
    if (_systemStress < 0.33) return 'STABLE';
    if (_systemStress < 0.66) return 'WARNING';
    return 'CRITICAL';
  }
}
