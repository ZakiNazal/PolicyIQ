import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sim_models.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final math.Random _random = math.Random();
  Timer? _simulationTimer;

  Stream<Map<String, dynamic>> get simulationStream => _simulationController.stream;
  final _simulationController = StreamController<Map<String, dynamic>>.broadcast();

  void startSimulation(Function() onTick) {
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      onTick();
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void broadcastUpdate(Map<String, dynamic> data) {
    if (!_simulationController.isClosed) {
      _simulationController.add(data);
    }
  }

  List<SimKnob> generateInitialKnobs() {
    return [
      SimKnob(
        id: 'tax_rate',
        label: 'Tax Rate',
        description: 'Percentage of citizen income collected',
        value: 35,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFF00E5FF),
      ),
      SimKnob(
        id: 'welfare',
        label: 'Welfare',
        description: 'Social support and healthcare funding',
        value: 60,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFF00FF9D),
      ),
      SimKnob(
        id: 'surveillance',
        label: 'Surveillance',
        description: 'Citizen monitoring and data collection',
        value: 25,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFFFFB347),
      ),
      SimKnob(
        id: 'media_control',
        label: 'Media Control',
        description: 'Information flow regulation',
        value: 40,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFFFF4466),
      ),
      SimKnob(
        id: 'innovation',
        label: 'Innovation',
        description: 'Technology and research investment',
        value: 70,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFFBB66FF),
      ),
      SimKnob(
        id: 'migration',
        label: 'Migration',
        description: 'Cross-border movement policies',
        value: 15,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFF4488FF),
      ),
      SimKnob(
        id: 'resource_scarcity',
        label: 'Resources',
        description: 'Available resources per capita',
        value: 30,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFF00E5FF),
      ),
      SimKnob(
        id: 'trust_index',
        label: 'Trust Index',
        description: 'Citizen trust in institutions',
        value: 55,
        min: 0,
        max: 100,
        unit: '%',
        accentColor: const Color(0xFF00FF9D),
      ),
    ];
  }

  Map<String, dynamic> generateRandomEvent() {
    final events = [
      {
        'type': 'economic_crisis',
        'title': 'Economic Crisis',
        'description': 'Market instability affects tax revenue',
        'impact': {'tax_rate': -10, 'welfare': -15},
      },
      {
        'type': 'technological_breakthrough',
        'title': 'Tech Breakthrough',
        'description': 'New innovation boosts productivity',
        'impact': {'innovation': 20, 'resource_scarcity': -10},
      },
      {
        'type': 'social_unrest',
        'title': 'Social Unrest',
        'description': 'Citizen protests demand change',
        'impact': {'surveillance': 15, 'media_control': 10},
      },
      {
        'type': 'resource_discovery',
        'title': 'Resource Discovery',
        'description': 'New resources found in remote regions',
        'impact': {'resource_scarcity': -25, 'migration': 5},
      },
    ];

    final event = events[_random.nextInt(events.length)];
    return {
      ...event,
      'timestamp': DateTime.now(),
      'severity': _random.nextDouble(),
    };
  }

  void dispose() {
    _simulationTimer?.cancel();
    _simulationController.close();
  }
}
