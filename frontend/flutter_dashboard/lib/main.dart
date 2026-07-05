import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/dashboard_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  await SupabaseService.instance.initialize();

  runApp(const InboxCfoApp());
}

class InboxCfoApp extends StatelessWidget {
  const InboxCfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'InboxCFO Dashboard',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
