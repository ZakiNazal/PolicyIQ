import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/system_models.dart';
import '../services/anomaly_engine.dart';
import '../services/simulation_engine.dart';

class AnomalyDashboardScreen extends StatefulWidget {
  const AnomalyDashboardScreen({super.key});

  @override
  State<AnomalyDashboardScreen> createState() => _AnomalyDashboardScreenState();
}

class _AnomalyDashboardScreenState extends State<AnomalyDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock data for demonstration
  final List<AnomalyDetection> _mockAnomalies = [
    AnomalyDetection(
      agentId: 'MY-0047',
      type: AnomalyType.breakingPoint,
      severity: AnomalySeverity.critical,
      description: 'Agent Ahmad Razak has reached breaking point (Financial: 5.2%, Sentiment: -85.0%)',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AnomalyDetection(
      agentId: 'MY-0012',
      type: AnomalyType.sentimentCrisis,
      severity: AnomalySeverity.high,
      description: 'Agent Siti Aminah experiencing severe distress',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  final List<LoopholeDetection> _mockLoopholes = [
    LoopholeDetection(
      agentId: 'MY-0023',
      type: LoopholeType.financialExploitation,
      description: 'Agent showing unusual financial gain patterns',
      severity: LoopholeSeverity.high,
      evidence: ['Tick 1: +RM500', 'Tick 2: +RM750', 'Tick 3: +RM1200'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnomaliesTab(),
                _buildLoopholesTab(),
                _buildMitigationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.warning_amber,
              color: AppTheme.accentRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anomaly Engine',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Policy Impact Analysis & Mitigation',
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
          _buildStatusBubble('CRITICAL', 2, AppTheme.accentRed),
          const SizedBox(width: 8),
          _buildStatusBubble('HIGH', 3, AppTheme.accentAmber),
          const SizedBox(width: 8),
          _buildStatusBubble('MEDIUM', 1, AppTheme.accentCyan),
        ],
      ),
    );
  }

  Widget _buildStatusBubble(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
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
          Tab(text: 'ANOMALIES'),
          Tab(text: 'LOOPHOLES'),
          Tab(text: 'MITIGATION'),
        ],
      ),
    );
  }

  Widget _buildAnomaliesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnomalySummary(),
          const SizedBox(height: 24),
          ..._mockAnomalies.map((anomaly) => _buildAnomalyCard(anomaly)),
        ],
      ),
    );
  }

  Widget _buildAnomalySummary() {
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
            'System Stability Score',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              const Text(
                '35%',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Critical stability threshold reached. Immediate policy review recommended.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyDetection anomaly) {
    final isCritical = anomaly.severity == AnomalySeverity.critical;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical ? AppTheme.accentRed.withOpacity(0.05) : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical ? AppTheme.accentRed.withOpacity(0.3) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: isCritical ? AppTheme.accentRed : AppTheme.accentAmber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  anomaly.description,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: isCritical ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSeverityColor(anomaly.severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  anomaly.severity.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: _getSeverityColor(anomaly.severity),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Agent: ${anomaly.agentId}',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(anomaly.timestamp),
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoopholesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected Loophole Exploitation',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._mockLoopholes.map((loophole) => _buildLoopholeCard(loophole)),
        ],
      ),
    );
  }

  Widget _buildLoopholeCard(LoopholeDetection loophole) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: AppTheme.accentAmber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loophole.description,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  loophole.type.name.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.accentAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Evidence:',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          ...loophole.evidence.map((evidence) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '• $evidence',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppTheme.textMuted,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMitigationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Policy Mitigation Suggestions',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMitigationCard(),
        ],
      ),
    );
  }

  Widget _buildMitigationCard() {
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: AppTheme.accentGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Policy Adjustment',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Confidence: 85%',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Implement targeted cash assistance for B40 households experiencing financial distress, with automatic eligibility based on simulation-detected breaking points. Add verification mechanisms to prevent exploitation while ensuring rapid disbursement to critical cases.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recommended Actions:',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...['Immediate emergency fund activation', 'Automated distress detection system', 'Policy safeguard implementation'].map((action) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              '• $action',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return AppTheme.accentRed;
      case AnomalySeverity.high:
        return AppTheme.accentAmber;
      case AnomalySeverity.medium:
        return AppTheme.accentCyan;
      case AnomalySeverity.low:
        return AppTheme.accentGreen;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
