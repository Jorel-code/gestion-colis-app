class HistoriqueLocalisation {
  final int idHistorique;
  final String dateHeure;
  final String lieu;
  final String statut;
  final String? commentaire;

  HistoriqueLocalisation({
    required this.idHistorique,
    required this.dateHeure,
    required this.lieu,
    required this.statut,
    this.commentaire,
  });

  factory HistoriqueLocalisation.fromJson(Map<String, dynamic> json) {
    return HistoriqueLocalisation(
      idHistorique: json['id_historique'],
      dateHeure: json['date_heure'].toString(),
      lieu: json['lieu'] ?? '',
      statut: json['statut'] ?? '',
      commentaire: json['commentaire'],
    );
  }
}
