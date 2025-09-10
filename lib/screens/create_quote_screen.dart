import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/produit.dart';
import '../models/devis.dart';
import '../models/item_devis.dart';
import '../theme/app_theme.dart';

class CreateQuoteScreen extends StatefulWidget {
  const CreateQuoteScreen({super.key});

  @override
  State<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour le formulaire
  final _clientController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Variables d'état
  Client? _selectedClient;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  List<ItemDevis> _items = [];
  bool _isLoading = false;
  String? _numeroDevis;

  @override
  void initState() {
    super.initState();
    _generateQuoteNumber();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateQuoteNumber() async {
    final numero = await _dbHelper.generateNumeroDevis();
    setState(() {
      _numeroDevis = numero;
    });
  }

  Future<void> _selectClient() async {
    final clients = await _dbHelper.getAllClients();
    
    if (clients.isEmpty) {
      _showAddClientDialog();
      return;
    }

    final selectedClient = await showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un client'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: clients.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Ajouter un nouveau client'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddClientDialog();
                  },
                );
              }
              
              final client = clients[index - 1];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    client.nom[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(client.nom),
                subtitle: Text(client.email),
                onTap: () => Navigator.pop(context, client),
              );
            },
          ),
        ),
      ),
    );

    if (selectedClient != null) {
      setState(() {
        _selectedClient = selectedClient;
        _clientController.text = selectedClient.nom;
      });
    }
  }

  Future<void> _showAddClientDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'Nom du client',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'client@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '+33 1 23 45 67 89',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'Adresse complète',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final client = Client(
          nom: nameController.text,
          email: emailController.text,
          telephone: phoneController.text.isNotEmpty ? phoneController.text : null,
          adresse: addressController.text.isNotEmpty ? addressController.text : null,
          dateCreation: DateTime.now(),
        );

        final clientId = await _dbHelper.insertClient(client);
        final newClient = client.copyWith(id: clientId);

        setState(() {
          _selectedClient = newClient;
          _clientController.text = newClient.nom;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client ajouté avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'ajout du client: $e')),
          );
        }
      }
    }
  }

  Future<void> _addProduct() async {
    final products = await _dbHelper.getAllProduits();
    
    if (products.isEmpty) {
      _showAddProductDialog();
      return;
    }

    final selectedProduct = await showDialog<Produit>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un produit'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Ajouter un nouveau produit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddProductDialog();
                  },
                );
              }
              
              final product = products[index - 1];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentColor,
                  child: const Icon(Icons.inventory, color: Colors.white),
                ),
                title: Text(product.nom),
                subtitle: Text('${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(product.prixUnitaire)} ${product.unite ?? ''}'),
                onTap: () => Navigator.pop(context, product),
              );
            },
          ),
        ),
      ),
    );

    if (selectedProduct != null) {
      _showQuantityDialog(selectedProduct);
    }
  }

  Future<void> _showAddProductDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'Nom du produit',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Description du produit',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire *',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unité',
                  hintText: 'pièce, heure, kg, etc.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  descriptionController.text.isNotEmpty && 
                  priceController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final product = Produit(
          nom: nameController.text,
          description: descriptionController.text,
          prixUnitaire: double.parse(priceController.text),
          unite: unitController.text.isNotEmpty ? unitController.text : null,
          dateCreation: DateTime.now(),
        );

        final productId = await _dbHelper.insertProduit(product);
        final newProduct = product.copyWith(id: productId);

        _showQuantityDialog(newProduct);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'ajout du produit: $e')),
          );
        }
      }
    }
  }

  Future<void> _showQuantityDialog(Produit product) async {
    final quantityController = TextEditingController(text: '1');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter ${product.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Prix unitaire: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(product.prixUnitaire)}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                hintText: '1',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      final quantity = double.tryParse(quantityController.text) ?? 1.0;
      final total = quantity * product.prixUnitaire;

      final item = ItemDevis(
        devisId: 0, // Sera mis à jour lors de la sauvegarde
        produitId: product.id!,
        nom: product.nom,
        description: product.description,
        quantite: quantity,
        prixUnitaire: product.prixUnitaire,
        total: total,
        unite: product.unite,
        produit: product,
      );

      setState(() {
        _items.add(item);
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un produit')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final devis = Devis(
        clientId: _selectedClient!.id!,
        numero: _numeroDevis!,
        dateCreation: DateTime.now(),
        dateEcheance: _selectedDate,
        total: _calculateTotal(),
        statut: 'brouillon',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final devisId = await _dbHelper.insertDevis(devis);

      // Sauvegarder les items
      for (final item in _items) {
        final itemToSave = item.copyWith(devisId: devisId);
        await _dbHelper.insertItemDevis(itemToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devis créé avec succès')),
        );
        
        // Réinitialiser le formulaire
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du devis: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedClient = null;
      _clientController.clear();
      _notesController.clear();
      _items.clear();
      _selectedDate = DateTime.now().add(const Duration(days: 30));
    });
    _generateQuoteNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Devis'),
        actions: [
          if (_numeroDevis != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  _numeroDevis!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section client
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientController,
                        decoration: const InputDecoration(
                          labelText: 'Client',
                          hintText: 'Sélectionner un client',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        readOnly: true,
                        onTap: _selectClient,
                        validator: (value) {
                          if (_selectedClient == null) {
                            return 'Veuillez sélectionner un client';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section date d'échéance
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date d\'échéance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section produits
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
                            'Produits',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          ElevatedButton.icon(
                            onPressed: _addProduct,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun produit ajouté',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cliquez sur "Ajouter" pour commencer',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
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
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nom,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.quantite} × ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(item.prixUnitaire)}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(item.total),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeItem(index),
                                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
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
              ),

              const SizedBox(height: 16),

              // Section notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optionnel)',
                          hintText: 'Informations supplémentaires...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section total
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(_calculateTotal()),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resetForm,
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveQuote,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Créer le devis'),
                    ),
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
