import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/devis.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import '../services/pdf_service.dart';
import '../models/item_devis.dart';
import '../models/entreprise.dart';
import 'quote_detail_screen.dart';
import 'create_quote_screen.dart';
import 'enterprise_screen.dart';

class QuotesListScreen extends StatefulWidget {
  const QuotesListScreen({super.key});

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PdfService _pdfService = PdfService();
  final TextEditingController _searchController = TextEditingController();
  List<Devis> _allQuotes = [];
  List<Devis> _filteredQuotes = [];
  bool _isLoading = true;
  String _selectedStatus = 'Tous';

  final List<String> _statusOptions = [
    'Tous',
    'Brouillon',
    'Envoyé',
    'Accepté',
    'Refusé'
  ];

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
            icon: const Icon(Icons.business),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnterpriseScreen(),
                ),
              );
            },
            tooltip: 'Mon entreprise',
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
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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
            if (_searchController.text.isEmpty &&
                _selectedStatus == 'Tous') ...[
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      context.read<SettingsService>().formatAmount(quote.total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  QuoteDetailScreen(quote: quote),
                            ),
                          ).then((_) => _loadQuotes());
                        },
                        tooltip: 'Voir',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(quote),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload),
                        onPressed: () => _sendQuote(quote),
                        tooltip: 'Envoyer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _downloadQuote(quote),
                        tooltip: 'Télécharger',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmAndDelete(quote),
                        tooltip: 'Supprimer',
                        color: AppTheme.errorColor,
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

extension on _QuotesListScreenState {
  Future<void> _showEditDialog(Devis quote) async {
    final notesController = TextEditingController(text: quote.notes ?? '');
    String statut = quote.statut;
    bool tvaApplicable = quote.tvaApplicable;
    String templateType = quote.templateType ?? 'services';
    double tvaRate = quote.tvaRate ?? 20.0;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${quote.numero}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: statut,
                items: const [
                  DropdownMenuItem(
                      value: 'brouillon', child: Text('Brouillon')),
                  DropdownMenuItem(value: 'envoyé', child: Text('Envoyé')),
                  DropdownMenuItem(value: 'accepté', child: Text('Accepté')),
                  DropdownMenuItem(value: 'refusé', child: Text('Refusé')),
                ],
                onChanged: (v) => statut = v!,
                decoration: const InputDecoration(labelText: 'Statut'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: templateType,
                items: const [
                  DropdownMenuItem(
                      value: 'auto_entrepreneur',
                      child: Text('Auto-entrepreneur')),
                  DropdownMenuItem(
                      value: 'services',
                      child: Text('Prestataire de services')),
                  DropdownMenuItem(value: 'batiment', child: Text('Bâtiment')),
                ],
                onChanged: (v) => templateType = v!,
                decoration: const InputDecoration(labelText: 'Modèle PDF'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: tvaApplicable,
                onChanged: (v) {
                  tvaApplicable = v;
                },
                title: const Text('TVA applicable'),
              ),
              if (tvaApplicable) ...[
                TextFormField(
                  initialValue: tvaRate.toString(),
                  decoration:
                      const InputDecoration(labelText: 'Taux de TVA (%)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => tvaRate = double.tryParse(v) ?? tvaRate,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );

    if (result == true) {
      final updated = quote.copyWith(
        statut: statut,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        tvaApplicable: tvaApplicable,
        tvaRate: tvaApplicable ? tvaRate : null,
        templateType: templateType,
      );
      await _dbHelper.updateDevis(updated);
      await _loadQuotes();
    }
  }

  Future<void> _sendQuote(Devis quote) async {
    try {
      final items = await _dbHelper.getItemsDevis(quote.id!);
      final entreprises = await _dbHelper.getAllEntreprises();
      final ent = entreprises.isNotEmpty ? entreprises.first : null;
      final pdfFile = await _pdfService.generateQuotePDF(
        quote,
        items,
        entreprise: ent,
      );
      await _pdfService.sharePDF(pdfFile, quote.client?.email ?? '');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur envoi: $e')));
      }
    }
  }

  Future<void> _downloadQuote(Devis quote) async {
    try {
      final items = await _dbHelper.getItemsDevis(quote.id!);
      final entreprises = await _dbHelper.getAllEntreprises();
      final ent = entreprises.isNotEmpty ? entreprises.first : null;
      final pdfFile = await _pdfService.generateQuotePDF(
        quote,
        items,
        entreprise: ent,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF enregistré: ${pdfFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur téléchargement: $e')));
      }
    }
  }

  Future<void> _confirmAndDelete(Devis quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le devis'),
        content: Text('Voulez-vous supprimer ${quote.numero} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _dbHelper.deleteDevis(quote.id!);
        await _loadQuotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${quote.numero} supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }
}
