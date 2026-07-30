import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/colis.dart';
import '../services/api_service.dart';

class AjouterColisScreen extends StatefulWidget {
  const AjouterColisScreen({super.key});

  @override
  State<AjouterColisScreen> createState() => _AjouterColisScreenState();
}

class _AjouterColisScreenState extends State<AjouterColisScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Générée une seule fois à l'ouverture de l'écran : si l'envoi échoue
  // (réseau coupé, timeout Render...) et que l'utilisateur retape sur
  // "Enregistrer", c'est TOUJOURS la même clé qui repart — le serveur
  // reconnaît alors qu'il s'agit de la même tentative et ne duplique pas.
  final String _cleIdempotence = const Uuid().v4();

  final _descController = TextEditingController();
  final _poidsController = TextEditingController();

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _agences = [];
  
  int? _idExpediteur, _idDestinataire, _idAgenceDepart, _idAgenceArrivee;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      final clients = await _apiService.obtenirClients();
      final agences = await _apiService.obtenirAgences();
      setState(() {
        _clients = clients;
        _agences = agences;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement : $e')));
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    final nouveauColis = Colis(
      description: _descController.text,
      poids: double.parse(_poidsController.text),
      idClientExpediteur: _idExpediteur!,
      idClientDestinataire: _idDestinataire!,
      idAgenceDepart: _idAgenceDepart!,
      idAgenceArrivee: _idAgenceArrivee!,
    );

    try {
      await _apiService.ajouterColis(nouveauColis, idempotencyKey: _cleIdempotence);
      if (mounted) {
        context.pop(true); // true = un colis a bien été ajouté
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Colis ajouté avec succès')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un colis')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                TextFormField(controller: _poidsController, decoration: const InputDecoration(labelText: 'Poids (kg)'), keyboardType: TextInputType.number, validator: (v){
                  if (v == null || v.isEmpty) return 'Le poid est requis';
                  final poids = double.tryParse(v);
                  if (poids == null || poids <= 0) return 'Entrez un poids valide (>0)';
                  return null;
                },
                ),
                
                _buildDropdown('Client expéditeur', _clients, 'id_client', (val) => _idExpediteur = val),
                _buildDropdown('Client destinataire', _clients, 'id_client', (val) => _idDestinataire = val),
                _buildDropdown('Agence départ', _agences, 'id_agence', (val) => _idAgenceDepart = val),
                _buildDropdown('Agence arrivée', _agences, 'id_agence', (val) => _idAgenceArrivee = val),
                
                const SizedBox(height: 20),
                FilledButton(onPressed: _soumettre, child: const Text('Enregistrer le colis')),
              ],
            ),
          ),
    );
  }

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, String idKey, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(labelText: label),
      items: items.map((item) => DropdownMenuItem<int>(
        value: item[idKey],
        // Un client a nom+prenom ; une agence n'a qu'un nom. On distingue
        // via idKey plutôt que via containsKey('nom'), car les deux ont
        // une clé 'nom' et ça affichait "null Agence Centrale".
        child: Text(idKey == 'id_client' ? '${item['prenom']} ${item['nom']}' : item['nom']),
      )).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Sélectionnez une option' : null,
    );
  }
}