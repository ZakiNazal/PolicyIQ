import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/system_models.dart';
import '../data/agent_population.dart';
import '../services/rag_service.dart';

class MicroInsightsScreen extends StatefulWidget {
  const MicroInsightsScreen({super.key});

  @override
  State<MicroInsightsScreen> createState() => _MicroInsightsScreenState();
}

class _MicroInsightsScreenState extends State<MicroInsightsScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showMonologue = true;
  late AnimationController _glitchCtrl;
  late Animation<double> _glitchAnim;
  bool _jsonPanelCollapsed = false;
  final TextEditingController _searchController = TextEditingController();
  List<AgentDNA> _filteredAgents = [];
  String _activeFilter = 'ALL';
  late List<AgentDNA> _mockAgents;

  @override
  void initState() {
    super.initState();
    _mockAgents = AgentPopulation.generateDigitalMalaysians();
    _filteredAgents = List.from(_mockAgents);
    _searchController.addListener(_onSearchChanged);
    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _glitchAnim = Tween<double>(begin: 0, end: 1).animate(_glitchCtrl);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _glitchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    List<AgentDNA> baseList = _mockAgents;

    if (_activeFilter != 'ALL') {
      baseList = baseList.where((agent) {
        switch (_activeFilter) {
          case 'CRITICAL':
            return agent.anomalyFlag == 'CRITICAL';
          case 'WATCH':
            return agent.anomalyFlag == 'WATCH';
          case 'NORMAL':
            return agent.anomalyFlag == 'NORMAL';
          default:
            return true;
        }
      }).toList();
    }

    if (query.isNotEmpty) {
      baseList = baseList.where((agent) =>
          agent.name.toLowerCase().contains(query) ||
          agent.occupationType.name.toLowerCase().contains(query) ||
          agent.locationMatrix.name.toLowerCase().contains(query) ||
          agent.incomeTier.name.toLowerCase().contains(query)
      ).toList();
    }

    setState(() {
      _filteredAgents = baseList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilter(),
          Expanded(
            child: Row(
              children: [
                _buildAgentList(),
                _buildDetailPanel(),
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
              color: AppTheme.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.radar,
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
                  'CITIZEN INSIGHTS',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Digital Malaysians - Agent DNA Profiles',
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
          _buildStatusBubble('${_filteredAgents.length} AGENTS', AppTheme.accentCyan),
          const SizedBox(width: 8),
          _buildStatusBubble('${_mockAgents.where((a) => a.anomalyFlag == 'CRITICAL').length} CRITICAL', AppTheme.accentRed),
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search agents by name, occupation, location...',
                        hintStyle: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          ...['ALL', 'CRITICAL', 'WATCH', 'NORMAL'].map((filter) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildFilterChip(filter, _activeFilter == filter),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.accentCyan : AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppTheme.accentCyan : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            color: active ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentList() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 12, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: const Text(
                'AGENT LIST',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredAgents.length,
                itemBuilder: (context, index) {
                  final agent = _filteredAgents[index];
                  return _buildAgentListItem(agent, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentListItem(AgentDNA agent, int index) {
    final isSelected = _selectedIndex == index;
    final anomalyColor = agent.anomalyFlag == 'CRITICAL' 
        ? AppTheme.accentRed 
        : agent.anomalyFlag == 'WATCH' 
            ? AppTheme.accentAmber 
            : AppTheme.accentGreen;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (agent.anomalyFlag == 'CRITICAL') {
          _glitchCtrl.forward().then((_) => _glitchCtrl.reverse());
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceElevated : AppTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? anomalyColor : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: anomalyColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    agent.name,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? anomalyColor : AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  agent.anomalyFlag,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: anomalyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  agent.occupationType.name.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  agent.locationMatrix.name,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  agent.incomeTier.name,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_filteredAgents.isEmpty) return const SizedBox.shrink();
    
    final agent = _filteredAgents[_selectedIndex];
    final anomalyColor = agent.anomalyFlag == 'CRITICAL' 
        ? AppTheme.accentRed 
        : agent.anomalyFlag == 'WATCH' 
            ? AppTheme.accentAmber 
            : AppTheme.accentGreen;

    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: anomalyColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            _buildAgentHeader(agent, anomalyColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAgentDNA(agent),
                    const SizedBox(height: 24),
                    _buildEconomicProfile(agent),
                    const SizedBox(height: 24),
                    _buildSensitivityMatrix(agent),
                    const SizedBox(height: 24),
                    _buildRAGContext(agent),
                    const SizedBox(height: 24),
                    _buildMonologueSection(agent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentHeader(AgentDNA agent, Color anomalyColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: anomalyColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _glitchAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.sin(_glitchAnim.value * math.pi * 4) * 2,
                      0,
                    ),
                    child: Text(
                      agent.name,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: anomalyColor,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: anomalyColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  agent.anomalyFlag,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${agent.id} | ${agent.occupationType.name.replaceAll('_', ' ')} | ${agent.locationMatrix.name}',
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentDNA(AgentDNA agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('AGENT DNA'),
        const SizedBox(height: 12),
        _buildDNARow('ID', agent.id),
        _buildDNARow('Name', agent.name),
        _buildDNARow('Income Tier', agent.incomeTier.name),
        _buildDNARow('Occupation', agent.occupationType.name.replaceAll('_', ' ')),
        _buildDNARow('Location', agent.locationMatrix.name),
        _buildDNARow('Current Sentiment', agent.currentSentiment.toStringAsFixed(3)),
        _buildDNARow('Financial Health', agent.financialHealth.toStringAsFixed(3)),
        _buildDNARow('Anomaly Flag', agent.anomalyFlag),
      ],
    );
  }

  Widget _buildDNARow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEconomicProfile(AgentDNA agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('ECONOMIC ENTITY'),
        const SizedBox(height: 12),
        _buildEconomicRow('Monthly Income', 'RM${agent.monthlyIncomeRm.toStringAsFixed(0)}'),
        _buildEconomicRow('Liquid Savings', 'RM${agent.liquidSavingsRm.toStringAsFixed(0)}'),
        _buildEconomicRow('Debt/Income Ratio', '${(agent.debtToIncomeRatio * 100).toStringAsFixed(1)}%'),
        _buildEconomicRow('Dependents', '${agent.dependentsCount}'),
        _buildEconomicRow('Digital Readiness', (agent.digitalReadinessScore * 100).toStringAsFixed(1) + '%'),
        _buildEconomicRow('BRIM Subsidy', agent.subsidyFlags['brim'] == true ? 'YES' : 'NO'),
        _buildEconomicRow('Petrol Subsidy', agent.subsidyFlags['petrol'] == true ? 'YES' : 'NO'),
      ],
    );
  }

  Widget _buildEconomicRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityMatrix(AgentDNA agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('SENSITIVITY MATRIX'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              const Text(
                'Agent sensitivity to Universal Knobs:',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...UniversalKnobType.values.map((knobType) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        knobType.name.replaceAll('_', ' '),
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.5, // Mock sensitivity value
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '0.5',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRAGContext(AgentDNA agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('RAG CONTEXT'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Retrieved context for agent decision-making:',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• DOSM 2024 Q3: ${agent.incomeTier.name} household average income: RM${(agent.monthlyIncomeRm * 1.2).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• ${agent.locationMatrix.name} region unemployment rate: ${(4.5 + agent.financialHealth * 2).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• ${agent.occupationType.name.replaceAll('_', ' ')} sector growth: ${(2.3 + agent.currentSentiment).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonologueSection(AgentDNA agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionLabel('INTERNAL MONOLOGUE'),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMonologue = !_showMonologue;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showMonologue ? AppTheme.accentCyan : AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.accentCyan),
                ),
                child: Text(
                  _showMonologue ? 'HIDE' : 'SHOW',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: _showMonologue ? Colors.white : AppTheme.accentCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_showMonologue)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...agent.monologueHistory.map((monologue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '"$monologue"',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )),
              ],
            ),
          ),
      ],
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
