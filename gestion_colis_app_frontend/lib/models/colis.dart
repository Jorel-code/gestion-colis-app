class Colis {
  final int? idColis;
  final String description;
  final double poids;
  final String statut;
  final int idClientExpediteur;
  final int idClientDestinataire;
  final int idAgenceDepart;
  final int idAgenceArrivee;
  // Uniquement renseignés par GET /colis (liste), grâce à la jointure SQL.
  // Restent null pour un Colis créé localement ou récupéré via GET /colis/<id>.
  final String? nomExpediteur;
  final String? nomDestinataire;

  Colis({
    this.idColis,
    required this.description,
    required this.poids,
    this.statut = 'Enregistré',
    required this.idClientExpediteur,
    required this.idClientDestinataire,
    required this.idAgenceDepart,
    required this.idAgenceArrivee,
    this.nomExpediteur,
    this.nomDestinataire,
  });

  factory Colis.fromJson(Map<String, dynamic> json) {
    String? construireNom(String? prenom, String? nom) {
      if (prenom == null && nom == null) return null;
      return '${prenom ?? ''} ${nom ?? ''}'.trim();
    }

    // MySQL renvoie les colonnes DECIMAL (comme "poids") et Flask les
    // sérialise parfois en texte (ex. "0.10") plutôt qu'en nombre JSON.
    // On accepte donc les deux formats pour éviter un plantage.
    double parserPoids(dynamic valeur) {
      if (valeur is num) return valeur.toDouble();
      return double.parse(valeur.toString());
    }

    return Colis(
      idColis: json['id_colis'],
      description: json['description'],
      poids: parserPoids(json['poids']),
      statut: json['statut'] ?? 'Enregistré',
      idClientExpediteur: json['id_client_expediteur'],
      idClientDestinataire: json['id_client_destinataire'],
      idAgenceDepart: json['id_agence_depart'],
      idAgenceArrivee: json['id_agence_arrivee'],
      nomExpediteur: construireNom(json['prenom_expediteur'], json['nom_expediteur']),
      nomDestinataire: construireNom(json['prenom_destinataire'], json['nom_destinataire']),
    );
  }

  // On n'envoie pas idColis ni statut : ils sont gérés par le serveur
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'poids': poids,
      'id_client_expediteur': idClientExpediteur,
      'id_client_destinataire': idClientDestinataire,
      'id_agence_depart': idAgenceDepart,
      'id_agence_arrivee': idAgenceArrivee,
    };
  }
}
