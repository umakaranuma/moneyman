import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'services/category_service.dart';
import 'services/budget_service.dart';
import 'services/account_service.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await StorageService.init();
  await CategoryService.init();
  await BudgetService.init();
  await AccountService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Manager',
      theme: AppTheme.darkTheme, // Use dark theme by default
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark mode
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
