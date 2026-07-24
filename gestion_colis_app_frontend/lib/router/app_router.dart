import 'package:go_router/go_router.dart';
import '../screens/accueil_screen.dart';
import '../screens/ajouter_agent_screen.dart';
import '../screens/ajouter_colis_screen.dart';
import '../screens/detail_colis_screen.dart';
import '../screens/login_screen.dart';
import '../screens/statistiques_screen.dart';
import '../services/api_service.dart'; // Import important

// Initialisation du service
final ApiService _apiService = ApiService();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  // Logique de protection des routes
  redirect: (context, state) {
    final bool estConnecte = _apiService.estConnecte;
    final bool vaVersLogin = state.matchedLocation == '/login';

    if (!estConnecte && !vaVersLogin) {
      return '/login';
    }
    if (estConnecte && vaVersLogin) {
      return '/';
    }
    // Les routes /admin/* sont réservées aux comptes admin ; un agent qui
    // taperait l'URL directement est renvoyé à l'accueil.
    if (state.matchedLocation.startsWith('/admin') && !_apiService.estAdmin) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const AccueilScreen(),
    ),
    GoRoute(
      path: '/statistiques',
      builder: (context, state) => const StatistiquesScreen(),
    ),
    GoRoute(
      path: '/admin/ajouter-agent',
      builder: (context, state) => const AjouterAgentScreen(),
    ),
    GoRoute(
      path: '/ajouter',
      builder: (context, state) => const AjouterColisScreen(),
    ),
    GoRoute(
      path: '/colis/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetailColisScreen(idColis: id);
      },
    ),
  ],
);