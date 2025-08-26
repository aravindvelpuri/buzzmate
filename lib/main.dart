import 'package:buzzmate/migrate_users.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import './screens/splash_screen.dart';
import './theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/email_service.dart';
import 'models/chat_model.dart';
import 'models/message_model.dart';
import 'models/group_model.dart';
import 'models/scheduled_message_model.dart';
import 'services/presence_service.dart';
import 'services/block_service.dart';
import 'providers/theme_provider.dart';

final themeProvider = ThemeProvider(); // GLOBAL INSTANCE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(ChatModelAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(GroupModelAdapter());
  Hive.registerAdapter(ScheduledMessageModelAdapter());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await PresenceService().initialize();
  await BlockService().initialize();
  await EmailService.cleanupExpiredOTPs();
  await migrateExistingUsers();

  runApp(const BuzzMateApp());
}

class BuzzMateApp extends StatelessWidget {
  const BuzzMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeProvider,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'BuzzMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
