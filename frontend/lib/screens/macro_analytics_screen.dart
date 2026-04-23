import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/system_models.dart';
import '../services/simulation_engine.dart';

class MacroAnalyticsScreen extends StatefulWidget {
  const MacroAnalyticsScreen({super.key});

  @override
  State<MacroAnalyticsScreen> createState() => _MacroAnalyticsScreenState();
}

class _MacroAnalyticsScreenState extends State<MacroAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Mock simulation data for demonstration
  late Map<String, dynamic> _mockMacroMetrics;
  late List<AgentDNA> _mockAgents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _initializeMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    _mockMacroMetrics = {
      'totalAgents': 50,
      'avgSentiment': 0.15,
      'negativeSentimentCount': 12,
      'positiveSentimentCount': 18,
      'avgFinancialHealth': 0.65,
      'criticalFinancialCount': 8,
      'stableFinancialCount': 25,
      'criticalAgentsCount': 5,
      'watchAgentsCount': 7,
      'b40Count': 20,
      'm40Count': 20,
      't20Count': 10,
      'overallSystemStress': 0.42,
      'economicPressure': 0.58,
      'socialStability': 0.72,
    };

    // Generate mock agents for demonstration
    _mockAgents = List.generate(50, (index) {
      final incomeTier = index < 20 ? IncomeTier.B40 : index < 40 ? IncomeTier.M40 : IncomeTier.T20;
      return AgentDNA(
        id: 'MY-${(index + 1).toString().padLeft(4, '0')}',
        name: 'Agent ${index + 1}',
        incomeTier: incomeTier,
        occupationType: OccupationType.values[index % 5],
        locationMatrix: LocationMatrix.values[index % 3],
        monthlyIncomeRm: 2000.0 + (index * 100),
        liquidSavingsRm: 1000.0 + (index * 50),
        debtToIncomeRatio: 0.3 + (index % 10) * 0.05,
        dependentsCount: index % 4,
        digitalReadinessScore: 0.3 + (index % 7) * 0.1,
        subsidyFlags: {'brim': index < 20, 'petrol': index < 30},
        sensitivityWeights: {},
        currentSentiment: -0.5 + (index % 20) * 0.05,
        financialHealth: 0.2 + (index % 15) * 0.05,
        monologueHistory: ['Initial state'],
        currentState: {},
        anomalyFlag: index < 5 ? 'CRITICAL' : index < 12 ? 'WATCH' : 'NORMAL',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildDemographicsTab(),
                  _buildTimelineTab(),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Macro Analytics'),
              const SizedBox(height: 4),
              const Text(
                'Societal Metrics Dashboard',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Post-simulation aggregate analysis — Cycle ${_mockMacroMetrics['totalAgents']}',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildStatBubble('${_mockMacroMetrics['totalAgents']} Agents', AppTheme.accentCyan),
          const SizedBox(width: 10),
          _buildStatBubble('${_mockMacroMetrics['criticalAgentsCount']} Critical', AppTheme.accentRed),
          const SizedBox(width: 10),
          _buildStatBubble('Tick ${_mockMacroMetrics['totalAgents']}', AppTheme.accentAmber),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String label, Color color) {
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

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        controller: _tabController,
        indicator: BoxDecoration(
          
          color: AppTheme.accentCyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        labelColor: AppTheme.accentCyan,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 11,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'DEMOGRAPHICS'),
          Tab(text: 'TIMELINE'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemSummary(),
          const SizedBox(height: 24),
          _buildKeyMetrics(),
          const SizedBox(height: 24),
          _buildSystemStability(),
        ],
      ),
    );
  }

  Widget _buildSystemSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('System Summary'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Average Sentiment',
                  '${((_mockMacroMetrics['avgSentiment'] as double) * 100).toStringAsFixed(1)}%',
                  _mockMacroMetrics['avgSentiment'] > 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Financial Health',
                  '${((_mockMacroMetrics['avgFinancialHealth'] as double) * 100).toStringAsFixed(1)}%',
                  AppTheme.accentCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'System Stress',
                  '${((_mockMacroMetrics['overallSystemStress'] as double) * 100).toStringAsFixed(1)}%',
                  _mockMacroMetrics['overallSystemStress'] > 0.6 ? AppTheme.accentRed : AppTheme.accentAmber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Social Stability',
                  '${((_mockMacroMetrics['socialStability'] as double) * 100).toStringAsFixed(1)}%',
                  AppTheme.accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Key Metrics'),
          const SizedBox(height: 16),
          _buildMetricRow('Total Agents', '${_mockMacroMetrics['totalAgents']}', AppTheme.accentCyan),
          _buildMetricRow('Critical Agents', '${_mockMacroMetrics['criticalAgentsCount']}', AppTheme.accentRed),
          _buildMetricRow('Watch List', '${_mockMacroMetrics['watchAgentsCount']}', AppTheme.accentAmber),
          _buildMetricRow('Stable Agents', '${_mockMacroMetrics['stableFinancialCount']}', AppTheme.accentGreen),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStability() {
    final stability = _mockMacroMetrics['socialStability'] as double;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('System Stability'),
          const SizedBox(height: 16),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: stability,
              child: Container(
                decoration: BoxDecoration(
                  color: stability > 0.7 ? AppTheme.accentGreen : stability > 0.4 ? AppTheme.accentAmber : AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stability > 0.7 ? 'STABLE' : stability > 0.4 ? 'MODERATE' : 'UNSTABLE',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: stability > 0.7 ? AppTheme.accentGreen : stability > 0.4 ? AppTheme.accentAmber : AppTheme.accentRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIncomeDistribution(),
          const SizedBox(height: 24),
          _buildOccupationBreakdown(),
          const SizedBox(height: 24),
          _buildLocationAnalysis(),
        ],
      ),
    );
  }

  Widget _buildIncomeDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Income Distribution'),
          const SizedBox(height: 16),
          _buildIncomeTierBar('B40', _mockMacroMetrics['b40Count'] as int, AppTheme.accentRed),
          _buildIncomeTierBar('M40', _mockMacroMetrics['m40Count'] as int, AppTheme.accentAmber),
          _buildIncomeTierBar('T20', _mockMacroMetrics['t20Count'] as int, AppTheme.accentGreen),
        ],
      ),
    );
  }

  Widget _buildIncomeTierBar(String tier, int count, Color color) {
    final total = _mockMacroMetrics['totalAgents'] as int;
    final percentage = (count / total) * 100;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tier,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '$count agents (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupationBreakdown() {
    final occupationCounts = <String, int>{};
    for (final agent in _mockAgents) {
      final occupation = agent.occupationType.name;
      occupationCounts[occupation] = (occupationCounts[occupation] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Occupation Breakdown'),
          const SizedBox(height: 16),
          ...occupationCounts.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  entry.key.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entry.value} agents',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLocationAnalysis() {
    final locationCounts = <String, int>{};
    for (final agent in _mockAgents) {
      final location = agent.locationMatrix.name;
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Location Analysis'),
          const SizedBox(height: 16),
          ...locationCounts.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entry.value} agents',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Simulation Timeline'),
          const SizedBox(height: 16),
          _buildTimelineChart(),
        ],
      ),
    );
  }

  Widget _buildTimelineChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agent Status Over Time',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMockTimelineData(),
        ],
      ),
    );
  }

  Widget _buildMockTimelineData() {
    final ticks = List.generate(10, (index) => index + 1);
    
    return Column(
      children: [
        _buildTimelineLegend(),
        const SizedBox(height: 12),
        ...ticks.map((tick) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'T$tick',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    _buildTimelineBar('Normal', 30 + tick * 2, AppTheme.accentGreen),
                    _buildTimelineBar('Watch', 8 + tick ~/ 2, AppTheme.accentAmber),
                    _buildTimelineBar('Critical', 5 - tick ~/ 3, AppTheme.accentRed),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTimelineLegend() {
    return Row(
      children: [
        _buildLegendItem('Normal', AppTheme.accentGreen),
        const SizedBox(width: 16),
        _buildLegendItem('Watch', AppTheme.accentAmber),
        const SizedBox(width: 16),
        _buildLegendItem('Critical', AppTheme.accentRed),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineBar(String label, int count, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (count / 50).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 8,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
