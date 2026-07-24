import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/colis.dart';

class PdfService {
  /// Construit le PDF en mémoire (ne l'affiche ni ne le sauvegarde) :
  /// c'est Printing (dans l'écran) qui se charge de l'afficher/partager.
  static Future<Uint8List> genererRecu(Colis colis) async {
    final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(logoImage, height: 48),
                  pw.Text(
                    'Reçu de colis',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Text(
                'Colis #${colis.idColis}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              _ligneInfo('Description', colis.description),
              _ligneInfo('Poids', '${colis.poids} kg'),
              _ligneInfo('Statut actuel', colis.statut),
              pw.SizedBox(height: 32),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Merci de votre confiance.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 11),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _ligneInfo(String libelle, String valeur) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(libelle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(valeur),
        ],
      ),
    );
  }
}
