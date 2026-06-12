import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/meal_repository.dart';
import 'providers/meal_provider.dart';
import 'screens/home_screen.dart';
import 'app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // 1. Register the repository (data layer)
        Provider(create: (_) => MealRepository()),

        // 2. Register the provider, injecting the repository
        ChangeNotifierProxyProvider<MealRepository, MealProvider>(
          create: (ctx) => MealProvider(ctx.read<MealRepository>()),
          update: (_, repo, prev) => prev ?? MealProvider(repo),
        ),
      ],
      child: const PlanerApp(),
    ),
  );
}

class PlanerApp extends StatelessWidget {
  const PlanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planer Posiłków',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
