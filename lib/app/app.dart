import 'package:flutter/material.dart';

import 'theme.dart';
import '../screens/home_screen.dart';

class ChartLensApp extends StatelessWidget {
  const ChartLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChartLens',
      theme: ChartLensTheme.light,
      home: const HomeScreen(),
    );
  }
}