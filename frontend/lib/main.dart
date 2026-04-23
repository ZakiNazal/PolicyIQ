import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:window_size/window_size.dart';
import 'theme/app_theme.dart';
import 'models/system_models.dart';
import 'data/agent_population.dart';
import 'services/gatekeeper_service.dart';
import 'services/decomposition_service.dart';
import 'services/simulation_engine.dart';
import 'services/rag_service.dart';
import 'services/anomaly_engine.dart';
import 'screens/gatekeeper_screen.dart';
import 'screens/control_panel_screen.dart';
import 'screens/macro_analytics_screen.dart';
import 'screens/micro_insights_screen.dart';
import 'screens/anomaly_dashboard_screen.dart';
import 'dart:async'; // For Timer and DateTime

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // Configure window for desktop platforms
    configureWindow();
  }
  
  runApp(const PolicyIQApp());
}

void configureWindow() {
  if (defaultTargetPlatform == TargetPlatform.windows || 
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    setWindowMinSize(const Size(1200, 800));
    setWindowMaxSize(Size.infinite);
  }
}

class PolicyIQApp extends StatelessWidget {
  const PolicyIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolicyIQ - Advanced Policy Analysis Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _bootCtrl;
  late Animation<double> _bootAnim;
  bool _booted = false;
  DateTime _currentTime = DateTime.now();
  late Timer _timeTimer;
  final List<_NavItem> _navItems = [
    const _NavItem(
      icon: Icons.policy,
      label: 'POLICY INPUT',
      sublabel: 'Gatekeeper Validation',
      accentColor: AppTheme.accentCyan,
    ),
    const _NavItem(
      icon: Icons.tune,
      label: 'UNIVERSAL KNOBS',
      sublabel: '8-Knob Physics Engine',
      accentColor: AppTheme.accentAmber,
    ),
    const _NavItem(
      icon: Icons.analytics,
      label: 'MACRO SENTIMENT',
      sublabel: 'Regional Analysis',
      accentColor: AppTheme.accentGreen,
    ),
    const _NavItem(
      icon: Icons.radar,
      label: 'CITIZEN INSIGHTS',
      sublabel: 'Digital Malaysians',
      accentColor: AppTheme.accentRed,
    ),
    const _NavItem(
      icon: Icons.warning_amber,
      label: 'ANOMALY ENGINE',
      sublabel: 'Policy Impact Analysis',
      accentColor: AppTheme.accentPurple,
    ),
  ];
  void _navigateTo(int index) {
    if (index < 0 || index >= _navItems.length) return;
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _bootCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bootAnim = CurvedAnimation(parent: _bootCtrl, curve: Curves.easeOut);
    
    // Initialize time timer to update every second
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _bootCtrl.forward().then((_) => setState(() => _booted = true));
    });
  }

  @override
  void dispose() {
    _bootCtrl.dispose();
    _timeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      GatekeeperScreen(onNavigate: _navigateTo),
      const ControlPanelScreen(),
      const MacroAnalyticsScreen(),
      const MicroInsightsScreen(),
      const AnomalyDashboardScreen(),
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildGlobalTopBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _bootAnim,
                    child: screens[_currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalTopBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentCyan.withOpacity(0.03),
            blurRadius: 20,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final showTitle = w >= 820;
          final showCitizens = w >= 980;
          final showAnomalies = w >= 1120;
          final showTime = w >= 760;

          return Row(
            children: [
              // Left cluster
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                  border:
                      Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                ),
                child: const Center(
                  child: Text(
                    'PQ',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 14,
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10, height: 30),
              if (showTitle)
                const Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'POLICYIQ - MALAYSIA',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      _TopBarTag(),
                    ],
                  ),
                )
              else
                const Spacer(),

              // Right cluster
              _buildStatusItem('CYCLE', '047', AppTheme.accentCyan),
              if (showCitizens) ...[
                const SizedBox(width: 20),
                _buildStatusItem('CITIZENS', '1,247', AppTheme.accentGreen),
              ],
              if (showAnomalies) ...[
                const SizedBox(width: 20),
                _buildStatusItem('ANOMALIES', '3', AppTheme.accentRed),
              ],
              if (showTime) ...[
                const SizedBox(width: 20),
                _buildStatusItem('TIME', _formatTime(_currentTime), AppTheme.textSecondary),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 72,
      color: AppTheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...List.generate(_navItems.length, (i) => _buildNavButton(i)),
          const Spacer(),
          _buildSidebarDivider(),
          GestureDetector(
            onTap: () => _showInfoDialog(
              title: 'Settings',
              body:
                  'Settings UI isn’t wired yet.\n\nTip: Use Gatekeeper → Configure Knobs to jump into the Control Panel.',
            ),
            child: _buildSidebarIcon(Icons.settings, AppTheme.textMuted),
          ),
          GestureDetector(
            onTap: () => _showInfoDialog(
              title: 'Help',
              body:
                  'Quick flow:\n- Policy Input: type scenario, analyze\n- Control Panel: choose preset / adjust knobs\n- Macro + Citizen Insights: review outcomes',
            ),
            child: _buildSidebarIcon(Icons.help_outline, AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavButton(int index) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    return Tooltip(
      message: '${item.label}\n${item.sublabel}',
      preferBelow: false,
      child: GestureDetector(
        onTap: () => _navigateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 45,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
          decoration: BoxDecoration(
            color: isActive
                ? item.accentColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? item.accentColor.withOpacity(0.5)
                  : Colors.transparent,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Icon(
            item.icon,
            size: 20,
            color: isActive ? item.accentColor : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarDivider() {
    return Container(
      width: 32,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: AppTheme.border,
    );
  }

  void _showInfoDialog({required String title, required String body}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            body,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: AppTheme.accentCyan,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Icon(icon, size: 16, color: color),
    );
  }

  String _formatTime(DateTime dateTime) {
    // Format as YYYY-MM-DD HH:MM:SS for a futuristic feel
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color accentColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.accentColor,
  });
}

class _TopBarTag extends StatelessWidget {
  const _TopBarTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
      ),
      child: const Text(
        'POLICY SIM',
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 10,
          color: AppTheme.accentAmber,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
