import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/devis.dart';
import '../models/item_devis.dart';
import '../theme/app_theme.dart';
import '../services/pdf_service.dart';

class QuoteDetailScreen extends StatefulWidget {
  final Devis quote;

  const QuoteDetailScreen({super.key, required this.quote});

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ItemDevis> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuoteItems();
  }

  Future<void> _loadQuoteItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await _dbHelper.getItemsDevis(widget.quote.id!);
      setState(() {
        _items = items;
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

  Future<void> _generateAndSharePDF() async {
    try {
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateQuotePDF(widget.quote, _items);
      
      if (mounted) {
        // Afficher un dialogue pour demander l'email
        final email = await _showEmailDialog();
        if (email != null && email.isNotEmpty) {
          await pdfService.sharePDF(pdfFile, email);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF généré et envoyé avec succès')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
        );
      }
    }
  }

  Future<String?> _showEmailDialog() async {
    final emailController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email du destinataire'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Adresse email',
            hintText: 'client@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, emailController.text),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote.numero),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _generateAndSharePDF,
            tooltip: 'Partager le devis',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations du devis
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Informations du devis',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(widget.quote.statut).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getStatusText(widget.quote.statut),
                                  style: TextStyle(
                                    color: _getStatusColor(widget.quote.statut),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Numéro', widget.quote.numero),
                          _buildInfoRow('Client', widget.quote.client?.nom ?? 'N/A'),
                          _buildInfoRow('Email', widget.quote.client?.email ?? 'N/A'),
                          _buildInfoRow('Téléphone', widget.quote.client?.telephone ?? 'N/A'),
                          _buildInfoRow('Date de création', DateFormat('dd/MM/yyyy').format(widget.quote.dateCreation)),
                          _buildInfoRow('Date d\'échéance', DateFormat('dd/MM/yyyy').format(widget.quote.dateEcheance)),
                          _buildInfoRow('Total', NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(widget.quote.total)),
                          if (widget.quote.notes != null && widget.quote.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Notes:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.quote.notes!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Articles du devis
                  Text(
                    'Articles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  
                  if (_items.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun article',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ce devis ne contient aucun article',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.nom,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(item.total),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Quantité: ${item.quantite}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Prix unitaire: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(item.prixUnitaire)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (item.unite != null) ...[
                                      const SizedBox(width: 16),
                                      Text(
                                        'Unité: ${item.unite}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateAndSharePDF,
        icon: const Icon(Icons.share),
        label: const Text('Partager'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
