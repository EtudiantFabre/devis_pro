import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/devis.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import 'quote_detail_screen.dart';
import 'create_quote_screen.dart';

class QuotesListScreen extends StatefulWidget {
  const QuotesListScreen({super.key});

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  List<Devis> _allQuotes = [];
  List<Devis> _filteredQuotes = [];
  bool _isLoading = true;
  String _selectedStatus = 'Tous';

  final List<String> _statusOptions = ['Tous', 'Brouillon', 'Envoyé', 'Accepté', 'Refusé'];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _searchController.addListener(_filterQuotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quotes = await _dbHelper.getAllDevis();
      setState(() {
        _allQuotes = quotes;
        _filteredQuotes = quotes;
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

  void _filterQuotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredQuotes = _allQuotes.where((quote) {
        final matchesSearch = query.isEmpty ||
            quote.numero.toLowerCase().contains(query) ||
            quote.client?.nom.toLowerCase().contains(query) == true ||
            quote.client?.email!.toLowerCase().contains(query) == true;
        
        final matchesStatus = _selectedStatus == 'Tous' ||
            _getStatusText(quote.statut) == _selectedStatus;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterQuotes();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes Devis'),
            Text(
              '${_allQuotes.length} devis créés',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Option pour filtres avancés
            },
            tooltip: 'Filtrer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un devis...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Filtres par statut
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              itemBuilder: (context, index) {
                final status = _statusOptions[index];
                final isSelected = _selectedStatus == status;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onStatusChanged(status);
                      }
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Liste des devis
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadQuotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredQuotes.length,
                          itemBuilder: (context, index) {
                            final quote = _filteredQuotes[index];
                            return _buildQuoteCard(quote);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateQuoteScreen(),
            ),
          ).then((_) => _loadQuotes());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Devis'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _selectedStatus != 'Tous'
                  ? 'Aucun devis trouvé'
                  : 'Aucun devis créé',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty || _selectedStatus != 'Tous'
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Commencez par créer votre premier devis',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty && _selectedStatus == 'Tous') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateQuoteScreen(),
                    ),
                  ).then((_) => _loadQuotes());
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer un devis'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(Devis quote) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailScreen(quote: quote),
            ),
          ).then((_) => _loadQuotes());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    quote.numero,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(quote.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(quote.statut),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(quote.statut),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informations client
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quote.client?.nom ?? 'Client inconnu',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Description (si disponible)
              if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quote.notes!.length > 50 
                            ? '${quote.notes!.substring(0, 50)}...'
                            : quote.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Dates
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(quote.dateCreation)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Valide jusqu\'au ${DateFormat('dd/MM/yyyy').format(quote.dateEcheance)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Montant et actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.read<SettingsService>().formatAmount(quote.total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuoteDetailScreen(quote: quote),
                            ),
                          ).then((_) => _loadQuotes());
                        },
                        tooltip: 'Voir',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // TODO: Implémenter l'édition
                        },
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload),
                        onPressed: () {
                          // TODO: Implémenter l'envoi
                        },
                        tooltip: 'Envoyer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // TODO: Implémenter le téléchargement PDF
                        },
                        tooltip: 'Télécharger',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
