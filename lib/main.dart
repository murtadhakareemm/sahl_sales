import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'views/setup_wizard_screen.dart';
import 'views/login_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/activation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState()..initializeApp(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (!state.initialized) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل نظام سهل للمبيعات...',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        Widget homeScreen;
        if (!state.isLicensed && !state.isTrialActive) {
          homeScreen = const ActivationScreen();
        } else if (state.settings == null) {
          homeScreen = const SetupWizardScreen();
        } else if (state.activeEmployee == null) {
          homeScreen = const PinLoginScreen();
        } else {
          homeScreen = const DashboardScreen();
        }

        return MaterialApp(
          title: state.settings?.storeName ?? 'سهل للمبيعات',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(state.activeThemeCategory, isDark: state.isDarkMode),
          home: homeScreen,
        );
      },
    );
  }
}
