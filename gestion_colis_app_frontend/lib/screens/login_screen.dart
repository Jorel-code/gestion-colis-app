import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _connexionEnCours = false;
  String? _erreur;

  String? _requis(String? valeur) => (valeur == null || valeur.isEmpty) ? 'Requis' : null;

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _connexionEnCours = true;
      _erreur = null;
    });

    try {
      // 1. On appelle l'API (qui stocke automatiquement ton Token en mémoire)
      await _apiService.connexion(
        _emailController.text.trim(), 
        _motDePasseController.text
      );
      
      // 2. Le token étant validé et enregistré, GoRouter va nous laisser passer
      if (mounted) {
        context.go('/'); // On va vers l'accueil existant !
      }
    } catch (e) {
      setState(() => _erreur = 'Email ou mot de passe incorrect');
    } finally {
      if (mounted) setState(() => _connexionEnCours = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', height: 64),
                const SizedBox(height: 24),
                Text('Connexion', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _requis,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _motDePasseController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: _requis,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _connexionEnCours ? null : _seConnecter,
                    child: _connexionEnCours
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
