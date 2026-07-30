-- ============================================================
-- Base de données : Gestion de colis pour agence de voyage
-- ============================================================

CREATE DATABASE IF NOT EXISTS gestion_colis
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE gestion_colis;

-- Sans cette ligne, le client qui exécute ce script au démarrage de
-- Docker lit les caractères accentués avec le mauvais encodage, ce qui
-- les stocke doublement encodés dans la base ('é' devient 'Ã©', etc.)
-- même si la base et les colonnes sont bien déclarées en utf8mb4.
SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- Table AGENCE
-- ------------------------------------------------------------
CREATE TABLE Agence (
    id_agence      INT AUTO_INCREMENT PRIMARY KEY,
    nom            VARCHAR(100) NOT NULL,
    adresse        VARCHAR(255),
    ville          VARCHAR(100),
    telephone      VARCHAR(20),
    email          VARCHAR(100)
);

-- ------------------------------------------------------------
-- Table CLIENT
-- ------------------------------------------------------------
CREATE TABLE Client (
    id_client      INT AUTO_INCREMENT PRIMARY KEY,
    nom            VARCHAR(100) NOT NULL,
    prenom         VARCHAR(100) NOT NULL,
    telephone      VARCHAR(20),
    email          VARCHAR(100),
    adresse        VARCHAR(255)
);

-- ------------------------------------------------------------
-- Table COLIS
-- ------------------------------------------------------------
CREATE TABLE Colis (
    id_colis               INT AUTO_INCREMENT PRIMARY KEY,
    description             VARCHAR(255),
    poids                   DECIMAL(6,2),
    statut                  ENUM('Enregistré','Reçu','En transit','Arrivé','Livré','Perdu','Volé') DEFAULT 'Enregistré',
    id_client_expediteur    INT NOT NULL,
    id_client_destinataire  INT NOT NULL,
    id_agence_depart        INT NOT NULL,
    id_agence_arrivee       INT NOT NULL,
    date_enregistrement     DATETIME DEFAULT CURRENT_TIMESTAMP,
    idempotency_key         VARCHAR(36) UNIQUE,
    FOREIGN KEY (id_client_expediteur)   REFERENCES Client(id_client),
    FOREIGN KEY (id_client_destinataire) REFERENCES Client(id_client),
    FOREIGN KEY (id_agence_depart)       REFERENCES Agence(id_agence),
    FOREIGN KEY (id_agence_arrivee)      REFERENCES Agence(id_agence)
);

-- ------------------------------------------------------------
-- Table TRAJET
-- ------------------------------------------------------------
CREATE TABLE Trajet (
    id_trajet            INT AUTO_INCREMENT PRIMARY KEY,
    id_colis             INT NOT NULL,
    date_depart          DATETIME,
    date_arrivee_prevue  DATETIME,
    transporteur         VARCHAR(100),
    numero_vehicule      VARCHAR(50),
    statut_trajet        ENUM('Planifié','En cours','Terminé','Annulé') DEFAULT 'Planifié',
    FOREIGN KEY (id_colis) REFERENCES Colis(id_colis)
);

-- ------------------------------------------------------------
-- Table HISTORIQUE_LOCALISATION
-- ------------------------------------------------------------
CREATE TABLE Historique_Localisation (
    id_historique  INT AUTO_INCREMENT PRIMARY KEY,
    id_colis       INT NOT NULL,
    date_heure     DATETIME DEFAULT CURRENT_TIMESTAMP,
    lieu           VARCHAR(255),
    statut         VARCHAR(100),
    commentaire    VARCHAR(255),
    FOREIGN KEY (id_colis) REFERENCES Colis(id_colis)
);

-- ------------------------------------------------------------
-- Table UTILISATEUR (comptes pour se connecter à l'application)
-- ------------------------------------------------------------
CREATE TABLE Utilisateur (
    id_utilisateur     INT AUTO_INCREMENT PRIMARY KEY,
    email               VARCHAR(150) NOT NULL UNIQUE,
    mot_de_passe_hash   VARCHAR(255) NOT NULL
);

-- Utilisateur de test : email "test@agence.com" / mot de passe "test1234"
INSERT INTO Utilisateur (email, mot_de_passe_hash) VALUES
('test@agence.com', 'scrypt:32768:8:1$WFTtj7pvSx5wqeaB$b03db48e48ddffb072087d0ba035aced76f0f34e6fbfddd42b578e500af9a9e36f7229f9628a6b4fbe3c3ae2e3baac7e32d0d1fc05b2778d533a36fe7ab75f58');

-- ------------------------------------------------------------
-- Données de test (pour éviter les erreurs de clé étrangère
-- lors des essais avec Postman)
-- ------------------------------------------------------------
INSERT INTO Agence (nom, adresse, ville, telephone, email) VALUES
('Agence Centrale',   '12 rue de la Gare',    'Paris',    '0100000001', 'centrale@agence.com'),
('Agence Nord',       '5 avenue des Alpes',   'Lyon',     '0100000002', 'nord@agence.com'),
('Agence Sud',        '8 boulevard du Port',  'Marseille','0100000003', 'sud@agence.com');

INSERT INTO Client (nom, prenom, telephone, email, adresse) VALUES
('Martin', 'Sophie',   '0600000001', 'sophie.martin@mail.com',  '3 rue des Lilas, Paris'),
('Bernard', 'Karim',   '0600000002', 'karim.bernard@mail.com',  '7 rue du Marché, Lyon'),
('Dubois', 'Claire',   '0600000003', 'claire.dubois@mail.com',  '15 rue Victor Hugo, Marseille'),
('Petit', 'Nicolas',   '0600000004', 'nicolas.petit@mail.com',  '9 avenue Foch, Paris');

ALTER TABLE Utilisateur ADD COLUMN role VARCHAR(20) DEFAULT 'agent';
-- Met à jour ton compte actuel en compte administrateur
UPDATE Utilisateur SET role = 'admin' WHERE email = 'test@agence.com';