import 'dart:math';
import '../models/system_models.dart';

class AgentPopulation {
  static List<AgentDNA> generateDigitalMalaysians() {
    final agents = <AgentDNA>[];
    final random = Random(42); // Seed for reproducible results

    // Generate 50 agents following Malaysian demographics
    for (int i = 0; i < 50; i++) {
      agents.add(_generateAgent(i + 1, random));
    }

    return agents;
  }

  static AgentDNA _generateAgent(int id, Random random) {
    // Malaysian demographic distribution
    final incomeTier = _generateIncomeTier(random);
    final occupation = _generateOccupation(incomeTier, random);
    final location = _generateLocation(random);

    // Economic entity fields based on income tier
    final economicData = _generateEconomicData(incomeTier, random);

    // Sensitivity matrix based on demographic profile
    final sensitivityWeights = _generateSensitivityMatrix(
      incomeTier,
      occupation,
      location,
      economicData['digitalReadiness'],
    );

    return AgentDNA(
      id: 'MY-${id.toString().padLeft(4, '0')}',
      name: _generateMalaysianName(random),
      incomeTier: incomeTier,
      occupationType: occupation,
      locationMatrix: location,
      monthlyIncomeRm: economicData['income'],
      liquidSavingsRm: economicData['savings'],
      debtToIncomeRatio: economicData['debtRatio'],
      dependentsCount: economicData['dependents'],
      digitalReadinessScore: economicData['digitalReadiness'],
      subsidyFlags: economicData['subsidyFlags'],
      sensitivityWeights: sensitivityWeights,
    );
  }

  static IncomeTier _generateIncomeTier(Random random) {
    final roll = random.nextDouble();
    // Malaysian income distribution: B40 (40%), M40 (40%), T20 (20%)
    if (roll < 0.4) return IncomeTier.B40;
    if (roll < 0.8) return IncomeTier.M40;
    return IncomeTier.T20;
  }

  static OccupationType _generateOccupation(IncomeTier tier, Random random) {
    final roll = random.nextDouble();
    
    switch (tier) {
      case IncomeTier.B40:
        if (roll < 0.3) return OccupationType.gigWorker;
        if (roll < 0.6) return OccupationType.unemployed;
        if (roll < 0.85) return OccupationType.civilServant;
        return OccupationType.smeOwner;
      case IncomeTier.M40:
        if (roll < 0.4) return OccupationType.salariedCorporate;
        if (roll < 0.6) return OccupationType.civilServant;
        if (roll < 0.8) return OccupationType.smeOwner;
        return OccupationType.gigWorker;
      case IncomeTier.T20:
        if (roll < 0.5) return OccupationType.salariedCorporate;
        if (roll < 0.7) return OccupationType.smeOwner;
        if (roll < 0.9) return OccupationType.civilServant;
        return OccupationType.gigWorker;
    }
  }

  static LocationMatrix _generateLocation(Random random) {
    final roll = random.nextDouble();
    // Malaysian urbanization: Urban (45%), Suburban (35%), Rural (20%)
    if (roll < 0.45) return LocationMatrix.urban;
    if (roll < 0.8) return LocationMatrix.suburban;
    return LocationMatrix.rural;
  }

  static Map<String, dynamic> _generateEconomicData(IncomeTier tier, Random random) {
    double income, savings, debtRatio, digitalReadiness;
    int dependents;
    Map<String, bool> subsidyFlags;

    switch (tier) {
      case IncomeTier.B40:
        income = 2000 + random.nextDouble() * (4849 - 2000);
        savings = 200 + random.nextDouble() * (2000 - 200);
        debtRatio = 0.35 + random.nextDouble() * (0.65 - 0.35);
        dependents = 2 + random.nextInt(4); // 2-5 dependents
        digitalReadiness = 0.15 + random.nextDouble() * (0.50 - 0.15);
        subsidyFlags = {'brim': true, 'petrol': true, 'housing': random.nextBool()};
        break;
      case IncomeTier.M40:
        income = 4850 + random.nextDouble() * (10959 - 4850);
        savings = 2000 + random.nextDouble() * (15000 - 2000);
        debtRatio = 0.20 + random.nextDouble() * (0.45 - 0.20);
        dependents = 1 + random.nextInt(3); // 1-3 dependents
        digitalReadiness = 0.45 + random.nextDouble() * (0.78 - 0.45);
        subsidyFlags = {'brim': false, 'petrol': random.nextBool(), 'housing': false};
        break;
      case IncomeTier.T20:
        income = 10960 + random.nextDouble() * (30000 - 10960);
        savings = 15000 + random.nextDouble() * (80000 - 15000);
        debtRatio = 0.05 + random.nextDouble() * (0.25 - 0.05);
        dependents = random.nextInt(3); // 0-2 dependents
        digitalReadiness = 0.72 + random.nextDouble() * (0.98 - 0.72);
        subsidyFlags = {'brim': false, 'petrol': false, 'housing': false};
        break;
    }

    return {
      'income': income,
      'savings': savings,
      'debtRatio': debtRatio,
      'dependents': dependents,
      'digitalReadiness': digitalReadiness,
      'subsidyFlags': subsidyFlags,
    };
  }

  static Map<UniversalKnobType, double> _generateSensitivityMatrix(
    IncomeTier tier,
    OccupationType occupation,
    LocationMatrix location,
    double digitalReadiness,
  ) {
    final weights = <UniversalKnobType, double>{};

    // Base sensitivities by income tier
    switch (tier) {
      case IncomeTier.B40:
        weights[UniversalKnobType.disposableIncomeDelta] = 0.9;
        weights[UniversalKnobType.operationalExpenseIndex] = 0.8;
        weights[UniversalKnobType.capitalAccessPressure] = 0.7;
        weights[UniversalKnobType.systemicFriction] = 1.0 - digitalReadiness;
        weights[UniversalKnobType.socialEquityWeight] = 0.8;
        weights[UniversalKnobType.systemicTrustBaseline] = 0.6;
        weights[UniversalKnobType.futureMobilityIndex] = 0.7;
        weights[UniversalKnobType.ecologicalResourcePressure] = 0.4;
        break;
      case IncomeTier.M40:
        weights[UniversalKnobType.disposableIncomeDelta] = 0.7;
        weights[UniversalKnobType.operationalExpenseIndex] = 0.8;
        weights[UniversalKnobType.capitalAccessPressure] = 0.6;
        weights[UniversalKnobType.systemicFriction] = 0.8;
        weights[UniversalKnobType.socialEquityWeight] = 0.6;
        weights[UniversalKnobType.systemicTrustBaseline] = 0.7;
        weights[UniversalKnobType.futureMobilityIndex] = 0.8;
        weights[UniversalKnobType.ecologicalResourcePressure] = 0.5;
        break;
      case IncomeTier.T20:
        weights[UniversalKnobType.disposableIncomeDelta] = 0.5;
        weights[UniversalKnobType.operationalExpenseIndex] = 0.6;
        weights[UniversalKnobType.capitalAccessPressure] = 0.8;
        weights[UniversalKnobType.systemicFriction] = 0.4;
        weights[UniversalKnobType.socialEquityWeight] = 0.4;
        weights[UniversalKnobType.systemicTrustBaseline] = 0.8;
        weights[UniversalKnobType.futureMobilityIndex] = 0.9;
        weights[UniversalKnobType.ecologicalResourcePressure] = 0.7;
        break;
    }

    // Occupation-based adjustments
    switch (occupation) {
      case OccupationType.gigWorker:
        weights[UniversalKnobType.systemicFriction] = (weights[UniversalKnobType.systemicFriction]! + 0.2).clamp(0.0, 1.0);
        weights[UniversalKnobType.capitalAccessPressure] = (weights[UniversalKnobType.capitalAccessPressure]! + 0.1).clamp(0.0, 1.0);
        break;
      case OccupationType.salariedCorporate:
        weights[UniversalKnobType.futureMobilityIndex] = (weights[UniversalKnobType.futureMobilityIndex]! + 0.1).clamp(0.0, 1.0);
        weights[UniversalKnobType.systemicTrustBaseline] = (weights[UniversalKnobType.systemicTrustBaseline]! + 0.1).clamp(0.0, 1.0);
        break;
      case OccupationType.smeOwner:
        weights[UniversalKnobType.capitalAccessPressure] = (weights[UniversalKnobType.capitalAccessPressure]! + 0.3).clamp(0.0, 1.0);
        weights[UniversalKnobType.operationalExpenseIndex] = (weights[UniversalKnobType.operationalExpenseIndex]! + 0.2).clamp(0.0, 1.0);
        break;
      case OccupationType.civilServant:
        weights[UniversalKnobType.systemicTrustBaseline] = (weights[UniversalKnobType.systemicTrustBaseline]! + 0.2).clamp(0.0, 1.0);
        weights[UniversalKnobType.systemicFriction] = (weights[UniversalKnobType.systemicFriction]! - 0.1).clamp(0.0, 1.0);
        break;
      case OccupationType.unemployed:
        weights[UniversalKnobType.disposableIncomeDelta] = (weights[UniversalKnobType.disposableIncomeDelta]! + 0.2).clamp(0.0, 1.0);
        weights[UniversalKnobType.systemicFriction] = (weights[UniversalKnobType.systemicFriction]! + 0.3).clamp(0.0, 1.0);
        break;
    }

    // Location-based adjustments
    switch (location) {
      case LocationMatrix.urban:
        weights[UniversalKnobType.operationalExpenseIndex] = (weights[UniversalKnobType.operationalExpenseIndex]! + 0.1).clamp(0.0, 1.0);
        weights[UniversalKnobType.systemicFriction] = (weights[UniversalKnobType.systemicFriction]! + 0.1).clamp(0.0, 1.0);
        break;
      case LocationMatrix.rural:
        weights[UniversalKnobType.systemicFriction] = (weights[UniversalKnobType.systemicFriction]! + 0.2).clamp(0.0, 1.0);
        weights[UniversalKnobType.ecologicalResourcePressure] = (weights[UniversalKnobType.ecologicalResourcePressure]! + 0.1).clamp(0.0, 1.0);
        break;
      case LocationMatrix.suburban:
        // No adjustments for suburban (baseline)
        break;
    }

    // Normalize weights to 0.0-1.0 range
    weights.forEach((key, value) {
      weights[key] = value.clamp(0.0, 1.0);
    });

    return weights;
  }

  static String _generateMalaysianName(Random random) {
    final malayNames = [
      'Ahmad', 'Mohammad', 'Aziz', 'Hassan', 'Ibrahim', 'Omar', 'Bakar', 'Rahman',
      'Siti', 'Fatimah', 'Aishah', 'Khadijah', 'Zaharah', 'Mariam', 'Nur', 'Aminah',
    ];
    
    final chineseNames = [
      'Wei', 'Jia', 'Mei', 'Lin', 'Hui', 'Ying', 'Xin', 'Ping', 'Li', 'Wang',
      'Chen', 'Zhang', 'Liu', 'Yang', 'Huang', 'Zhao', 'Wu', 'Zhou', 'Xu', 'Sun',
    ];
    
    final indianNames = [
      'Raj', 'Kumar', 'Singh', 'Patel', 'Sharma', 'Gupta', 'Agarwal', 'Jain',
      'Priya', 'Anita', 'Sunita', 'Geeta', 'Rekha', 'Pooja', 'Kavita', 'Meena',
    ];

    final surnames = [
      'bin Abdullah', 'bin Ibrahim', 'bin Hassan', 'bin Omar',
      'a/p Kumar', 'a/l Raj', 'a/p Singh', 'a/p Patel',
      '@ Wong', '@ Tan', '@ Lim', '@ Lee', '@ Ng', '@ Ong',
    ];

    final nameRoll = random.nextDouble();
    List<String> firstNames;
    
    if (nameRoll < 0.6) {
      firstNames = malayNames;
    } else if (nameRoll < 0.85) {
      firstNames = chineseNames;
    } else {
      firstNames = indianNames;
    }

    final firstName = firstNames[random.nextInt(firstNames.length)];
    final surname = surnames[random.nextInt(surnames.length)];
    
    return '$firstName $surname';
  }
}
