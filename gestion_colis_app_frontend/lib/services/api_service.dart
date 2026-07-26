import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/colis.dart';
import '../models/historique.dart';

// Adresse du serveur Flask :
const String baseUrl = 'https://gestion-colis-app.onrender.com';

class ApiService {
  // Singleton : tous les écrans (et le routeur) doivent voir le même token.
  // Sans ça, se connecter dans login_screen ne serait visible que de cette
  // instance-là — le routeur et les autres écrans, avec leur propre
  // ApiService(), resteraient convaincus que personne n'est connecté.
  static final ApiService _instance = ApiService._interne();
  factory ApiService() => _instance;
  ApiService._interne();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  final _storage = const FlutterSecureStorage();

  // Jeton d'authentification. Gardé en mémoire pour un accès rapide,
  // et recopié dans un stockage chiffré pour survivre à la fermeture
  // de l'app — plus besoin de se reconnecter à chaque lancement.
  String? _token;
  String? _role;

  bool get estConnecte => _token != null;
  bool get estAdmin => _role == 'admin';

  // À appeler une fois, au démarrage de l'app (voir main.dart), avant
  // d'afficher quoi que ce soit : restaure la session précédente si
  // elle existe encore.
  Future<void> restaurerSession() async {
    final token = await _storage.read(key: 'token');
    final role = await _storage.read(key: 'role');
    if (token != null) {
      _token = token;
      _role = role;
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  // Connexion : envoie email/mot de passe, récupère et stocke le token,
  // puis l'ajoute automatiquement à toutes les requêtes suivantes.
  Future<void> connexion(String email, String motDePasse) async {
    final response = await _dio.post('/login', data: {
      'email': email,
      'mot_de_passe': motDePasse,
    });

    _token = response.data['token'] as String;
    _role = response.data['role'] as String?;
    _dio.options.headers['Authorization'] = 'Bearer $_token';

    await _storage.write(key: 'token', value: _token);
    if (_role != null) await _storage.write(key: 'role', value: _role);
  }

  Future<void> deconnexion() async {
    _token = null;
    _role = null;
    _dio.options.headers.remove('Authorization');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'role');
  }

  Future<List<Colis>> obtenirTousLesColis() async {
    final response = await _dio.get('/colis');
    return (response.data as List).map((e) => Colis.fromJson(e)).toList();
  }

  Future<int> ajouterColis(Colis colis) async {
    final response = await _dio.post('/colis', data: colis.toJson());
    final data = response.data;
    if (data != null && data['id_colis'] != null) {
      return (data['id_colis'] as num).toInt();
    } else {
      return 0;
    }
  }

  Future<Colis> obtenirColis(int idColis) async {
    final response = await _dio.get('/colis/$idColis');
    return Colis.fromJson(response.data);
  }

  Future<void> mettreAJourStatut(int idColis, String statut, {String? lieu, String? commentaire}) async {
    await _dio.put('/colis/$idColis/statut', data: {
      'statut': statut,
      if (lieu != null) 'lieu': lieu,
      if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
    });
  }

  Future<List<HistoriqueLocalisation>> obtenirHistorique(int idColis) async {
    final response = await _dio.get('/colis/$idColis/historique');
    return (response.data as List)
        .map((e) => HistoriqueLocalisation.fromJson(e))
        .toList();
  }

  // Renvoie le nombre de colis par statut, ex. {"Livré": 12, "En transit": 4}
  Future<Map<String, int>> obtenirStatistiques() async {
    final response = await _dio.get('/statistiques');
    final Map<String, int> stats = {};
    for (final ligne in response.data as List) {
      stats[ligne['statut'] as String] = (ligne['total'] as num).toInt();
    }
    return stats;
  }

  Future<List<Map<String, dynamic>>> obtenirClients() async {
  final response = await _dio.get('/clients');
  return (response.data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> obtenirAgences() async {
  final response = await _dio.get('/agences');
  return (response.data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> creerAgent(String email, String password) async {
    await _dio.post('/admin/ajouter-agent', data: {
      'email': email,
      'mot_de_passe': password,
    });
  }
}

