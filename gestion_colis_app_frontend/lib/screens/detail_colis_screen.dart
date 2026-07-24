import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/colis.dart';
import '../models/historique.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../widgets/colis_card.dart';

class DetailColisScreen extends StatefulWidget {
  final int idColis;
  const DetailColisScreen({super.key, required this.idColis});

  @override
  State<DetailColisScreen> createState() => _DetailColisScreenState();
}

class _DetailColisScreenState extends State<DetailColisScreen> {
  final ApiService _apiService = ApiService();
  Colis? _colis;
  List<HistoriqueLocalisation> _historique = [];
  bool _chargement = true;
  String? _erreur;

  static const List<String> _statutsPossibles = [
    'Enregistré', 'Reçu', 'En transit', 'Arrivé', 'Livré', 'Perdu', 'Volé',
  ];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final colis = await _apiService.obtenirColis(widget.idColis);
      final historique = await _apiService.obtenirHistorique(widget.idColis);
      setState(() {
        _colis = colis;
        _historique = historique;
        _erreur = null;
      });
    } catch (e) {
      setState(() => _erreur = 'Colis introuvable ou erreur réseau');
    } finally {
      setState(() => _chargement = false);
    }
  }

  // Demande une note optionnelle avant de confirmer le changement de statut.
  Future<void> _demanderNoteEtChanger(String nouveauStatut) async {
    final controleurNote = TextEditingController();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Passer au statut "$nouveauStatut"'),
        content: TextField(
          controller: controleurNote,
          decoration: const InputDecoration(
            labelText: 'Note (optionnelle)',
            hintText: 'Ex. remis en main propre, colis endommagé...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _changerStatut(nouveauStatut, note: controleurNote.text);
    }
  }

  Future<void> _changerStatut(String nouveauStatut, {String? note}) async {
    try {
      await _apiService.mettreAJourStatut(widget.idColis, nouveauStatut, commentaire: note);
      _chargerDonnees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _genererEtPartagerRecu() async {
    if (_colis == null) return;
    await Printing.layoutPdf(
      onLayout: (format) => PdfService.genererRecu(_colis!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Colis #${widget.idColis}'),
        actions: [
          if (_colis != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Générer le reçu PDF',
              onPressed: _genererEtPartagerRecu,
            ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(child: Text(_erreur!))
              : RefreshIndicator(
                  onRefresh: _chargerDonnees,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_colis != null) ColisCard(colis: _colis!),
                      const SizedBox(height: 16),
                      const Text('Changer le statut :',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _statutsPossibles.map((s) {
                          return ActionChip(
                            label: Text(s),
                            onPressed: () => _demanderNoteEtChanger(s),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text('Historique :',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._historique.map((h) => ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(h.statut),
                            subtitle: Text(
                              h.commentaire != null && h.commentaire!.isNotEmpty
                                  ? '${h.lieu} — ${h.dateHeure}\n${h.commentaire}'
                                  : '${h.lieu} — ${h.dateHeure}',
                            ),
                            isThreeLine: h.commentaire != null && h.commentaire!.isNotEmpty,
                          )),
                    ],
                  ),
                ),
    );
  }
}
