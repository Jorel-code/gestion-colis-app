import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuiviColisScreen extends StatefulWidget {
  final int idColis;

  const SuiviColisScreen({super.key, required this.idColis});

  @override
  State<SuiviColisScreen> createState() => _SuiviColisScreenState();
}

class _SuiviColisScreenState extends State<SuiviColisScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _historique = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    try {
      final data = await _apiService.obtenirHistorique(widget.idColis);
      if (mounted) {
        setState(() {
          _historique = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger le suivi : ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi du colis #${widget.idColis}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _historique.isEmpty
                  ? const Center(child: Text('Aucun historique disponible.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _historique.length,
                      itemBuilder: (context, index) {
                        final item = _historique[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.local_shipping, color: Colors.blue),
                            title: Text(item.statut),
                            subtitle: Text(
                              'Lieu : ${item.lieu}\n'
                              'Date : ${item.dateHeure}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}