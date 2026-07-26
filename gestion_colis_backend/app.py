import os
import decimal
from flask import Flask, request, jsonify
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity, get_jwt
)
from werkzeug.security import check_password_hash, generate_password_hash
from db import get_connection

app = Flask(__name__)

# Configuration de la clé secrète pour signer les JWT
# Sur Render, vous configurerez JWT_SECRET_KEY dans les "Environment Variables"
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "7f8c9b2a4e6d1f3c8b5a9e2d7f4c1b3a6e8d2f5c9b4a7e1d3f6c8b2a5e4d7f1c")
jwt = JWTManager(app)

STATUTS_VALIDES = ['Enregistré', 'Reçu', 'En transit', 'Arrivé', 'Livré', 'Perdu', 'Volé']


def convertir_decimals(ligne):
    """Convertit les décimaux MySQL en float pour le JSON."""
    for cle, valeur in ligne.items():
        if isinstance(valeur, decimal.Decimal):
            ligne[cle] = float(valeur)
    return ligne


# 0. Connexion : vérifie email/mot de passe, renvoie un JWT
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    mot_de_passe = data.get('mot_de_passe')

    if not email or not mot_de_passe:
        return jsonify({"erreur": "Email et mot de passe requis"}), 400

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Utilisateur WHERE email = %s", (email,))
    utilisateur = cursor.fetchone()
    cursor.close()
    conn.close()

    if not utilisateur or not check_password_hash(utilisateur['mot_de_passe_hash'], mot_de_passe):
        return jsonify({"erreur": "Email ou mot de passe incorrect"}), 401

    # Création du token JWT en y incluant l'ID et le rôle de l'utilisateur
    identity_data = {
        "id_utilisateur": utilisateur['id_utilisateur'],
        "role": utilisateur.get('role', 'agent')
    }
    
    # Le token contient l'identité chiffrée
    access_token = create_access_token(identity=str(utilisateur['id_utilisateur']),
    additional_claims={
        "role": utilisateur["role"]
    })

    return jsonify({
        "token": access_token,
        "id_utilisateur": utilisateur['id_utilisateur'],
        "email": utilisateur['email'],
        "role": utilisateur.get('role', 'agent')
    }), 200

@app.route('/admin/ajouter-agent', methods=['POST'])
@jwt_required()
def ajouter_agent():
    # Récupération des données de l'utilisateur stockées dans le JWT
    user_id = get_jwt_identity()
    claims = get_jwt()
    role = claims["role"]
    #current_user = get_jwt_identity()
    
    if role != 'admin':
        return jsonify({"erreur": "Accès réservé aux administrateurs"}), 403

    data = request.get_json()
    email = data.get('email')
    password = data.get('mot_de_passe')

    if not email or not password:
        return jsonify({"erreur": "Email et mot de passe requis"}), 400

    hash_password = generate_password_hash(password)
    
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("INSERT INTO Utilisateur (email, mot_de_passe_hash, role) VALUES (%s, %s, 'agent')", 
                       (email, hash_password))
        conn.commit()
    except Exception as e:
        return jsonify({"erreur": "Erreur lors de la création"}), 500
    finally:
        cursor.close(); conn.close()
        
    return jsonify({"message": "Agent ajouté avec succès"}), 201

# 1. Ajouter un colis
@app.route('/colis', methods=['POST'])
@jwt_required() # Remplace l'ancien décorateur personnalisé
def ajouter_colis():
    data = request.get_json()
    champs_requis = ['description', 'poids', 'id_client_expediteur',
                      'id_client_destinataire', 'id_agence_depart', 'id_agence_arrivee']
    for champ in champs_requis:
        if champ not in data:
            return jsonify({"erreur": f"Le champ '{champ}' est requis"}), 400

    conn = get_connection()
    cursor = conn.cursor()
    sql = """
        INSERT INTO Colis (description, poids, id_client_expediteur,id_client_destinataire, id_agence_depart, id_agence_arrivee)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    valeurs = (data['description'], data['poids'], data['id_client_expediteur'],
               data['id_client_destinataire'], data['id_agence_depart'], data['id_agence_arrivee'])
    cursor.execute(sql, valeurs)
    conn.commit()
    nouvel_id = cursor.lastrowid

    cursor.execute(
        "INSERT INTO Historique_Localisation (id_colis, lieu, statut) VALUES (%s, %s, %s)",
        (nouvel_id, "Agence de départ", "Enregistré")
    )
    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"message": "Colis ajouté avec succès", "id_colis": nouvel_id}), 201


# 1bis. Lister tous les colis
@app.route('/colis', methods=['GET'])
@jwt_required()
def lister_colis():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT c.*,
               ce.nom AS nom_expediteur, ce.prenom AS prenom_expediteur,
               cd.nom AS nom_destinataire, cd.prenom AS prenom_destinataire
        FROM Colis c
        JOIN Client ce ON c.id_client_expediteur = ce.id_client
        JOIN Client cd ON c.id_client_destinataire = cd.id_client
        ORDER BY c.date_enregistrement DESC
    """)
    resultats = cursor.fetchall()
    cursor.close()
    conn.close()

    resultats = [convertir_decimals(ligne) for ligne in resultats]
    return jsonify(resultats), 200


# 1ter. Récupérer un colis par son identifiant
@app.route('/colis/<int:id_colis>', methods=['GET'])
@jwt_required()
def obtenir_colis(id_colis):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Colis WHERE id_colis = %s", (id_colis,))
    colis = cursor.fetchone()
    cursor.close()
    conn.close()

    if not colis:
        return jsonify({"erreur": "Colis introuvable"}), 404

    colis = convertir_decimals(colis)
    return jsonify(colis), 200


# 2. Mettre à jour le statut d'un colis
@app.route('/colis/<int:id_colis>/statut', methods=['PUT'])
@jwt_required()
def maj_statut(id_colis):
    data = request.get_json()
    if 'statut' not in data:
        return jsonify({"erreur": "Le champ 'statut' est requis"}), 400
    if data['statut'] not in STATUTS_VALIDES:
        return jsonify({"erreur": f"Statut invalide. Valeurs possibles : {STATUTS_VALIDES}"}), 400

    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("UPDATE Colis SET statut = %s WHERE id_colis = %s", (data['statut'], id_colis))

        if cursor.rowcount == 0:
            return jsonify({"erreur": "Colis introuvable"}), 404

        conn.commit()

        cursor.execute(
            "INSERT INTO Historique_Localisation (id_colis, lieu, statut, commentaire) VALUES (%s, %s, %s, %s)",
            (id_colis, data.get('lieu', 'Non précisé'), data['statut'], data.get('commentaire'))
        )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Statut mis à jour avec succès"}), 200


# 3. Consulter l'historique d'un colis
@app.route('/colis/<int:id_colis>/historique', methods=['GET'])
@jwt_required()
def historique_colis(id_colis):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """SELECT id_historique, date_heure, lieu, statut, commentaire
           FROM Historique_Localisation WHERE id_colis = %s ORDER BY date_heure ASC""",
        (id_colis,)
    )
    resultats = cursor.fetchall()
    cursor.close()
    conn.close()

    if not resultats:
        return jsonify({"erreur": "Aucun historique trouvé pour ce colis"}), 404

    return jsonify(resultats), 200


# 4. Statistiques
@app.route('/statistiques', methods=['GET'])
@jwt_required()
def statistiques():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT statut, COUNT(*) AS total FROM Colis GROUP BY statut")
    resultats = cursor.fetchall()
    cursor.close()
    conn.close()

    return jsonify(resultats), 200


@app.route('/clients', methods=['GET'])
@jwt_required()
def lister_clients():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id_client, nom, prenom FROM Client")
    resultats = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(resultats), 200


@app.route('/agences', methods=['GET'])
@jwt_required()
def lister_agences():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id_agence, nom FROM Agence")
    resultats = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(resultats), 200


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)