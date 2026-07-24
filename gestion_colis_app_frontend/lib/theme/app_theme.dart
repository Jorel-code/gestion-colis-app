import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Toutes les couleurs de l'application, définies à un seul endroit.
/// Si un jour tu veux changer une teinte, tu ne modifies que ce fichier.
class AppColors {
  // Couleur principale : le bleu de ton logo (bouclier)
  static const Color primaire = Color(0xFF007BFF);
  static const Color primaireFonce = Color(0xFF0056B3); // état pressé / accents
  static const Color primaireClair = Color(0xFFE6F2FF); // fonds légers, badges

  // Gris doux pour le texte et les fonds
  static const Color texteFonce = Color(0xFF212529); // texte principal
  static const Color texteGris = Color(0xFF6C757D); // texte secondaire
  static const Color fond = Color(0xFFF8F9FA); // arrière-plan général
  static const Color bordure = Color(0xFFE9ECEF); // lignes, séparateurs
  static const Color blanc = Color(0xFFFFFFFF);

  // Couleurs de statut : rassurent l'utilisateur d'un coup d'œil
  static const Color succes = Color(0xFF28A745); // Livré
  static const Color attention = Color(0xFFFFC107); // En transit / Arrivé
  static const Color danger = Color(0xFFDC3545); // Perdu / Volé
  static const Color neutre = Color(0xFF6C757D); // Enregistré / Reçu

  /// Renvoie la couleur associée à un statut de colis.
  /// Utile pour colorer un badge ou une puce de statut.
  static Color couleurStatut(String statut) {
    switch (statut) {
      case 'Livré':
        return succes;
      case 'En transit':
      case 'Arrivé':
        return attention;
      case 'Perdu':
      case 'Volé':
        return danger;
      default:
        return neutre;
    }
  }
}

/// Le thème complet de l'application, à appliquer une seule fois
/// dans main.dart via MaterialApp.router(theme: AppTheme.lightTheme, ...)
class AppTheme {
  static ThemeData get lightTheme {
    final texte = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fond,
      primaryColor: AppColors.primaire,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaire,
        primary: AppColors.primaire,
      ),

      // Typographie : sans-serif moderne (Inter), lisible
      textTheme: texte.copyWith(
        headlineMedium: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.texteFonce),
        titleMedium: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.texteFonce),
        bodyMedium: GoogleFonts.inter(fontSize: 15, color: AppColors.texteFonce),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.texteGris),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.texteFonce,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.texteFonce),
      ),

      // Boutons pleins : arrondis, minimalistes, sans ombre marquée
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaire,
          foregroundColor: AppColors.blanc,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Boutons secondaires : contour bleu, fond transparent
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaire,
          side: const BorderSide(color: AppColors.primaire, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Cartes de colis : blanches, coins arrondis, ombre très légère
      cardTheme: CardThemeData(
        color: AppColors.blanc,
        elevation: 1,
        shadowColor: AppColors.texteGris.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),

      // Champs de formulaire : cohérents avec le reste (arrondis, fond blanc)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanc,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordure),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
