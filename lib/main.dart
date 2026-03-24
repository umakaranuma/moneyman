import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/passcode_lock_screen.dart';
import 'services/storage_service.dart';
import 'services/category_service.dart';
import 'services/budget_service.dart';
import 'services/account_service.dart';
import 'services/sms_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'core/router/app_router.dart';

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

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await StorageService.init();
  await CategoryService.init();
  await BudgetService.init();
  await AccountService.init();
  await SmsService.init();
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _requiresPasscode = false;
  bool _isUnlocked = false;
  String? _expectedPin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncPasscodeState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPasscodeState(lockOnRequire: true);
    }
  }

  void _syncPasscodeState({bool lockOnRequire = false}) {
    final passcodeEnabled = StorageService.getConfigPasscodeEnabled();
    final pin = StorageService.getConfigPin();
    final requires = passcodeEnabled && pin != null && pin.trim().length == 4;

    setState(() {
      _requiresPasscode = requires;
      _expectedPin = requires ? pin : null;
      if (!requires) {
        _isUnlocked = true;
      } else if (lockOnRequire || !_isUnlocked) {
        _isUnlocked = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finzo',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (_requiresPasscode && !_isUnlocked && _expectedPin != null) {
          return PasscodeLockScreen(
            expectedPin: _expectedPin!,
            onUnlocked: () {
              setState(() => _isUnlocked = true);
            },
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
