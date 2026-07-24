import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';

void main() async {
  // Nécessaire pour pouvoir utiliser le stockage sécurisé avant runApp()
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().restaurerSession();
  runApp(const GestionColisApp());
}

class GestionColisApp extends StatelessWidget {
  const GestionColisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gestion Colis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
