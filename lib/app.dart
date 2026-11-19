import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/guide_page.dart';
import 'pages/home_page.dart';
import 'providers/ledger_provider.dart';

/// 应用根组件。启动时根据「是否已授权通知读取」决定先显示引导页还是首页。
class AutoLedgerApp extends StatelessWidget {
  final bool startAtGuide;

  const AutoLedgerApp({super.key, required this.startAtGuide});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LedgerProvider()..load(),
      child: MaterialApp(
        title: '随手账',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F7DE0)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF6F7F9),
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
          ),
        ),
        home: startAtGuide ? const GuidePage() : const HomePage(),
      ),
    );
  }
}
