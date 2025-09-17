import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/produit.dart';
import '../theme/app_theme.dart';

class ManageClientsProductsScreen extends StatefulWidget {
  const ManageClientsProductsScreen({super.key});

  @override
  State<ManageClientsProductsScreen> createState() => _ManageClientsProductsScreenState();
}

class _ManageClientsProductsScreenState extends State<ManageClientsProductsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;
  
  List<Client> _clients = [];
  List<Produit> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clients = await _dbHelper.getAllClients();
      final products = await _dbHelper.getAllProduits();
      
      setState(() {
        _clients = clients;
        _products = products;
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

  Future<void> _showAddClientDialog({Client? client}) async {
    final nameController = TextEditingController(text: client?.nom ?? '');
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.telephone ?? '');
    final addressController = TextEditingController(text: client?.adresse ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Nouveau client' : 'Modifier le client'),
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
            child: Text(client == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        if (client == null) {
          // Ajouter un nouveau client
          final newClient = Client(
            nom: nameController.text,
            email: emailController.text,
            telephone: phoneController.text.isNotEmpty ? phoneController.text : null,
            adresse: addressController.text.isNotEmpty ? addressController.text : null,
            dateCreation: DateTime.now(),
          );

          final clientId = await _dbHelper.insertClient(newClient);
          final savedClient = newClient.copyWith(id: clientId);

          setState(() {
            _clients.add(savedClient);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client ajouté avec succès')),
            );
          }
        } else {
          // Modifier le client existant
          final updatedClient = client.copyWith(
            nom: nameController.text,
            email: emailController.text,
            telephone: phoneController.text.isNotEmpty ? phoneController.text : null,
            adresse: addressController.text.isNotEmpty ? addressController.text : null,
          );

          await _dbHelper.updateClient(updatedClient);

          setState(() {
            final index = _clients.indexWhere((c) => c.id == client.id);
            if (index != -1) {
              _clients[index] = updatedClient;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client modifié avec succès')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAddProductDialog({Produit? product}) async {
    final nameController = TextEditingController(text: product?.nom ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.prixUnitaire.toString() ?? '');
    final unitController = TextEditingController(text: product?.unite ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Nouveau produit' : 'Modifier le produit'),
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
            child: Text(product == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        if (product == null) {
          // Ajouter un nouveau produit
          final newProduct = Produit(
            nom: nameController.text,
            description: descriptionController.text,
            prixUnitaire: double.parse(priceController.text),
            unite: unitController.text.isNotEmpty ? unitController.text : null,
            dateCreation: DateTime.now(),
          );

          final productId = await _dbHelper.insertProduit(newProduct);
          final savedProduct = newProduct.copyWith(id: productId);

          setState(() {
            _products.add(savedProduct);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produit ajouté avec succès')),
            );
          }
        } else {
          // Modifier le produit existant
          final updatedProduct = product.copyWith(
            nom: nameController.text,
            description: descriptionController.text,
            prixUnitaire: double.parse(priceController.text),
            unite: unitController.text.isNotEmpty ? unitController.text : null,
          );

          await _dbHelper.updateProduit(updatedProduct);

          setState(() {
            final index = _products.indexWhere((p) => p.id == product.id);
            if (index != -1) {
              _products[index] = updatedProduct;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produit modifié avec succès')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteClient(Client client) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: Text('Êtes-vous sûr de vouloir supprimer le client "${client.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _dbHelper.deleteClient(client.id!);
        setState(() {
          _clients.removeWhere((c) => c.id == client.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client supprimé avec succès')),
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

  Future<void> _deleteProduct(Produit product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Êtes-vous sûr de vouloir supprimer le produit "${product.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _dbHelper.deleteProduit(product.id!);
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produit supprimé avec succès')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients & Produits'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Clients', icon: Icon(Icons.people)),
            Tab(text: 'Produits', icon: Icon(Icons.inventory)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Onglet Clients
                _buildClientsTab(),
                // Onglet Produits
                _buildProductsTab(),
              ],
            ),
    );
  }

  Widget _buildClientsTab() {
    return Column(
      children: [
        // En-tête avec bouton d'ajout
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_clients.length} client${_clients.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddClientDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        
        // Liste des clients
        Expanded(
          child: _clients.isEmpty
              ? _buildEmptyState(
                  icon: Icons.people_outline,
                  title: 'Aucun client',
                  subtitle: 'Commencez par ajouter votre premier client',
                  actionText: 'Ajouter un client',
                  onAction: () => _showAddClientDialog(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            client.nom[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          client.nom,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client.email ?? ''),
                            if (client.telephone != null) Text(client.telephone!),
                            if (client.adresse != null) Text(client.adresse!),
                            const SizedBox(height: 4),
                            Text(
                              'Ajouté le ${DateFormat('dd/MM/yyyy').format(client.dateCreation)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showAddClientDialog(client: client);
                                break;
                              case 'delete':
                                _deleteClient(client);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                  SizedBox(width: 8),
                                  Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // En-tête avec bouton d'ajout
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_products.length} produit${_products.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        
        // Liste des produits
        Expanded(
          child: _products.isEmpty
              ? _buildEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun produit',
                  subtitle: 'Commencez par ajouter votre premier produit',
                  actionText: 'Ajouter un produit',
                  onAction: () => _showAddProductDialog(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.accentColor,
                          child: const Icon(Icons.inventory, color: Colors.white),
                        ),
                        title: Text(
                          product.nom,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  context.read<SettingsService>().formatAmount(product.prixUnitaire),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (product.unite != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '/ ${product.unite}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ajouté le ${DateFormat('dd/MM/yyyy').format(product.dateCreation)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showAddProductDialog(product: product);
                                break;
                              case 'delete':
                                _deleteProduct(product);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                  SizedBox(width: 8),
                                  Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}
