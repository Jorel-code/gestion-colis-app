class Utilisateur {
  final int idUtilisateur;
  final String email;

  Utilisateur({required this.idUtilisateur, required this.email});

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      idUtilisateur: json['id_utilisateur'],
      email: json['email'],
    );
  }
}
