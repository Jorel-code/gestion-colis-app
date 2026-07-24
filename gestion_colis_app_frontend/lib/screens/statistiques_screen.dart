import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, int>> _futureStats;

  @override
  void initState() {
    super.initState();
    _futureStats = _apiService.obtenirStatistiques();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: FutureBuilder<Map<String, int>>(
        future: _futureStats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final stats = snapshot.data ?? {};
          if (stats.isEmpty) {
            return const Center(child: Text('Aucune donnée pour le moment'));
          }

          final total = stats.values.fold<int>(0, (a, b) => a + b);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: stats.entries.map((entree) {
                        final pourcentage = (entree.value / total * 100).toStringAsFixed(0);
                        return PieChartSectionData(
                          value: entree.value.toDouble(),
                          title: '$pourcentage%',
                          color: AppColors.couleurStatut(entree.key),
                          radius: 90,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Légende : couleur + nom du statut + nombre de colis
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: stats.entries.map((entree) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.couleurStatut(entree.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${entree.key} (${entree.value})'),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
