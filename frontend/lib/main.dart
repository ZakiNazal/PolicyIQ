/// main.dart — PolicyIQ Flutter Application Entrypoint
///
/// Bootstraps the Provider tree and launches the Dashboard.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_client.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(const PolicyIQApp());
}

class PolicyIQApp extends StatelessWidget {
  const PolicyIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Provides the API client to the entire widget tree.
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),

        /// SimulationState manages request parameters, streaming tick data,
        /// and the final SimulateResponse. Widgets listen to it for rebuilds.
        ChangeNotifierProvider<SimulationState>(
          create: (_) => SimulationState(),
        ),
      ],
      child: MaterialApp(
        title: 'PolicyIQ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
