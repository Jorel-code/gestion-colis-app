import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class AjouterAgentScreen extends StatefulWidget {
  const AjouterAgentScreen({super.key});

  @override
  State<AjouterAgentScreen> createState() => _AjouterAgentScreenState();
}

class _AjouterAgentScreenState extends State<AjouterAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _envoiEnCours = false;

  String? _requis(String? valeur) => (valeur == null || valeur.isEmpty) ? 'Requis' : null;

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoiEnCours = true);

    try {
      // Le nom n'est pas envoyé : ta table Utilisateur ne stocke
      // que l'email, le mot de passe (hashé) et le rôle.
      await _apiService.creerAgent(
        _emailController.text.trim(),
        _passController.text,
      );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Agent ajouté avec succès')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un agent')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _requis,
            ),
            TextFormField(
              controller: _passController,
              decoration: const InputDecoration(labelText: 'Mot de passe initial'),
              obscureText: true,
              validator: _requis,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _envoiEnCours ? null : _soumettre,
              child: _envoiEnCours
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }
}
