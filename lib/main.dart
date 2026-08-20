import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'data/models/student_model.dart';
import 'services/auth_service.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/main_navigation.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Client
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabasePublishableKey,
    );
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  // Check existing cached student session
  final StudentModel? existingStudent = await AuthService.getCurrentStudent();

  runApp(MailBaseApp(initialStudent: existingStudent));
}

class MailBaseApp extends StatelessWidget {
  final StudentModel? initialStudent;

  const MailBaseApp({super.key, this.initialStudent});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MailBase CDC Placement Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initialStudent != null
          ? MainNavigation(initialStudent: initialStudent)
          : const AuthScreen(),
    );
  }
}
