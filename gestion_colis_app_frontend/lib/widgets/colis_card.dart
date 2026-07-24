import 'package:flutter/material.dart';
import '../models/colis.dart';
import '../screens/suivi_colis_screen.dart'; // N'oublie pas l'import

class ColisCard extends StatelessWidget {
  final Colis colis;
  const ColisCard({super.key, required this.colis});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              colis.description,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Poids : ${colis.poids} kg'),
            Text('Statut actuel : ${colis.statut}'),
            const SizedBox(height: 8),
            // Ajout du bouton de suivi ici
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.history, color: Colors.blue),
                tooltip: 'Voir le suivi',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuiviColisScreen(idColis: colis.idColis!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
