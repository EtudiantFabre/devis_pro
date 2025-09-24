import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/devis.dart';
import '../theme/app_theme.dart';
import 'quote_detail_screen.dart';
import 'create_quote_screen.dart';
import 'manage_clients_products_screen.dart';
import 'quotes_list_screen.dart';
import 'audio_recording_screen.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Devis> _recentQuotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentQuotes();
  }

  Future<void> _loadRecentQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quotes = await _dbHelper.getAllDevis();
      setState(() {
        _recentQuotes = quotes.take(5).toList(); // Afficher les 5 plus récents
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'brouillon':
        return 'Brouillon';
      case 'envoyé':
        return 'Envoyé';
      case 'accepté':
        return 'Accepté';
      case 'refusé':
        return 'Refusé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'brouillon':
        return AppTheme.warningColor;
      case 'envoyé':
        return AppTheme.primaryColor;
      case 'accepté':
        return AppTheme.successColor;
      case 'refusé':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevisPro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecentQuotes,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _loadRecentQuotes());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentQuotes,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue sur DevisPro',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez des devis professionnels en toute simplicité',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Section de bienvenue
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16), // coins plus arrondis
                        side: BorderSide(
                            color: Colors.black.withOpacity(0.1), width: 1.0),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Navigation vers création de devis
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CreateQuoteScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Devis'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Navigation vers gestion clients/produits
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ManageClientsProductsScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.people),
                                    label: const Text('Clients'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Navigation vers enregistrement audio
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AudioRecordingScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.mic),
                                label: const Text('Enregistrement Audio'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side:
                                      BorderSide(color: AppTheme.primaryColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section statistiques
                    Text(
                      'Statistiques',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Devis',
                            _recentQuotes.length.toString(),
                            Icons.description,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Acceptés',
                            _recentQuotes
                                .where((q) => q.statut == 'accepté')
                                .length
                                .toString(),
                            Icons.check_circle,
                            AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'En Attente',
                            _recentQuotes
                                .where((q) => q.statut == 'envoyé')
                                .length
                                .toString(),
                            Icons.schedule,
                            AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Section devis récents
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Devis Récents',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuotesListScreen(),
                              ),
                            ).then((_) => _loadRecentQuotes());
                          },
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_recentQuotes.isEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                16), // coins plus arrondis
                            side: BorderSide(
                                color: Colors.black.withOpacity(0.1),
                                width: 1.0),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: AppTheme.textLight,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun devis créé',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Commencez par créer votre premier devis',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigation vers création de devis
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateQuoteScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Créer un devis'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentQuotes.length,
                        itemBuilder: (context, index) {
                          final quote = _recentQuotes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(quote.statut),
                                child: Icon(
                                  Icons.description,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                quote.numero,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quote.client?.nom ?? 'Client inconnu',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(quote.dateCreation),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    context
                                        .read<SettingsService>()
                                        .formatAmount(quote.total),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(quote.statut)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(quote.statut),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                _getStatusColor(quote.statut),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuoteDetailScreen(quote: quote),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card.outlined(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // coins plus arrondis
        side: BorderSide(color: Colors.black.withOpacity(0.1), width: 1.0),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
