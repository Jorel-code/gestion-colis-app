import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/colis.dart';
import '../services/api_service.dart';
import '../widgets/colis_card.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _rechercheController = TextEditingController();

  late Future<List<Colis>> _futureColis;

  // Le texte tapé est stocké séparément : il déclenche un simple
  // rebuild (setState) et un filtrage en mémoire, jamais un nouvel
  // appel réseau — _futureColis, lui, ne change pas.
  String _requeteRecherche = '';

  @override
  void initState() {
    super.initState();
    _futureColis = _apiService.obtenirTousLesColis();
    _rechercheController.addListener(() {
      setState(() => _requeteRecherche = _rechercheController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _rafraichir() async {
    setState(() {
      _futureColis = _apiService.obtenirTousLesColis();
    });
  }

  List<Colis> _filtrer(List<Colis> colisList) {
    if (_requeteRecherche.isEmpty) return colisList;
    return colisList.where((colis) {
      final idCorrespond = colis.idColis.toString().contains(_requeteRecherche);
      final expediteurCorrespond =
          (colis.nomExpediteur ?? '').toLowerCase().contains(_requeteRecherche);
      final destinataireCorrespond =
          (colis.nomDestinataire ?? '').toLowerCase().contains(_requeteRecherche);
      return idCorrespond || expediteurCorrespond || destinataireCorrespond;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Row(
    children: [
      Image.asset('assets/images/logo.png', height: 32),
      const SizedBox(width: 8),
      const Text('Gestion de colis'),
    ],
  ),
  actions: [
    // Icône des statistiques
    IconButton(
      icon: const Icon(Icons.bar_chart_outlined),
      tooltip: 'Statistiques',
      onPressed: () => context.push('/statistiques'),
    ),
    // Gestion des agents : réservée aux comptes admin
    if (_apiService.estAdmin)
      IconButton(
        icon: const Icon(Icons.person_add_alt_outlined),
        tooltip: 'Ajouter un agent',
        onPressed: () => context.push('/admin/ajouter-agent'),
      ),
    // Icône de déconnexion (maintenant bien placée dans les actions)
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Se déconnecter',
      onPressed: () async {
        await _apiService.deconnexion(); // Efface le token (mémoire + stockage)
        if (context.mounted) context.go('/login');
      },
    ),
  ],
),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _rechercheController,
              decoration: InputDecoration(
                hintText: 'Rechercher par ID ou nom de client',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _requeteRecherche.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _rechercheController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _rafraichir,
              child: FutureBuilder<List<Colis>>(
                future: _futureColis,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }

                  final colisFiltres = _filtrer(snapshot.data ?? []);
                  if (colisFiltres.isEmpty) {
                    return Center(
                      child: Text(_requeteRecherche.isEmpty
                          ? 'Aucun colis enregistré'
                          : 'Aucun résultat pour "$_requeteRecherche"'),
                    );
                  }

                  return ListView.builder(
                    itemCount: colisFiltres.length,
                    itemBuilder: (context, index) {
                      final colis = colisFiltres[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: GestureDetector(
                          onTap: () => context.push('/colis/${colis.idColis}'),
                          child: ColisCard(colis: colis),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final colisAjoute = await context.push<bool>('/ajouter');
          if (colisAjoute == true) _rafraichir();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
