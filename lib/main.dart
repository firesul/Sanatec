import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/router/app_router.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'firebase_options.dart';

import 'package:myapp/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar notificaciones
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();
  
  // Programar el recordatorio diario del check-in a las 10:00 AM
  await NotificationService.instance.scheduleDailyCheckIn();

  runApp(const MentalDataApp());
}

class MentalDataApp extends StatelessWidget {
  const MentalDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mental Data',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
