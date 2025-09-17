import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/produit.dart';
import '../models/devis.dart';
import '../models/item_devis.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'devis_pro.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table clients
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        email TEXT,
        telephone TEXT,
        adresse TEXT,
        date_creation INTEGER NOT NULL
      )
    ''');

    // Table produits
    await db.execute('''
      CREATE TABLE produits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT NOT NULL,
        prix_unitaire REAL NOT NULL,
        unite TEXT,
        date_creation INTEGER NOT NULL
      )
    ''');

    // Table devis
    await db.execute('''
      CREATE TABLE devis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        numero TEXT NOT NULL,
        date_creation INTEGER NOT NULL,
        date_echeance INTEGER NOT NULL,
        total REAL NOT NULL,
        statut TEXT NOT NULL DEFAULT 'brouillon',
        notes TEXT,
        FOREIGN KEY (client_id) REFERENCES clients (id)
      )
    ''');

    // Table items_devis
    await db.execute('''
      CREATE TABLE items_devis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        devis_id INTEGER NOT NULL,
        produit_id INTEGER,
        nom TEXT NOT NULL,
        description TEXT NOT NULL,
        quantite REAL NOT NULL,
        prix_unitaire REAL NOT NULL,
        total REAL NOT NULL,
        unite TEXT,
        FOREIGN KEY (devis_id) REFERENCES devis (id),
        FOREIGN KEY (produit_id) REFERENCES produits (id)
      )
    ''');
  }

  // Méthodes pour les clients
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  Future<Client?> getClient(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les produits
  Future<int> insertProduit(Produit produit) async {
    final db = await database;
    return await db.insert('produits', produit.toMap());
  }

  Future<List<Produit>> getAllProduits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('produits');
    return List.generate(maps.length, (i) => Produit.fromMap(maps[i]));
  }

  Future<Produit?> getProduit(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'produits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Produit.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduit(Produit produit) async {
    final db = await database;
    return await db.update(
      'produits',
      produit.toMap(),
      where: 'id = ?',
      whereArgs: [produit.id],
    );
  }

  Future<int> deleteProduit(int id) async {
    final db = await database;
    return await db.delete(
      'produits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les devis
  Future<int> insertDevis(Devis devis) async {
    final db = await database;
    return await db.insert('devis', devis.toMap());
  }

  Future<List<Devis>> getAllDevis() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devis',
      orderBy: 'date_creation DESC',
    );
    
    List<Devis> devis = [];
    for (var map in maps) {
      final client = await getClient(map['client_id']);
      devis.add(Devis.fromMap(map, client: client));
    }
    return devis;
  }

  Future<Devis?> getDevis(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devis',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final client = await getClient(maps.first['client_id']);
      return Devis.fromMap(maps.first, client: client);
    }
    return null;
  }

  Future<int> updateDevis(Devis devis) async {
    final db = await database;
    return await db.update(
      'devis',
      devis.toMap(),
      where: 'id = ?',
      whereArgs: [devis.id],
    );
  }

  Future<int> deleteDevis(int id) async {
    final db = await database;
    // Supprimer d'abord les items du devis
    await db.delete(
      'items_devis',
      where: 'devis_id = ?',
      whereArgs: [id],
    );
    // Puis supprimer le devis
    return await db.delete(
      'devis',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les items de devis
  Future<int> insertItemDevis(ItemDevis item) async {
    final db = await database;
    return await db.insert('items_devis', item.toMap());
  }

  Future<List<ItemDevis>> getItemsDevis(int devisId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items_devis',
      where: 'devis_id = ?',
      whereArgs: [devisId],
    );
    
    List<ItemDevis> items = [];
    for (var map in maps) {
      Produit? produit;
      if (map['produit_id'] != null) {
        produit = await getProduit(map['produit_id']);
      }
      items.add(ItemDevis.fromMap(map, produit: produit));
    }
    return items;
  }

  Future<int> updateItemDevis(ItemDevis item) async {
    final db = await database;
    return await db.update(
      'items_devis',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItemDevis(int id) async {
    final db = await database;
    return await db.delete(
      'items_devis',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItemsDevis(int devisId) async {
    final db = await database;
    return await db.delete(
      'items_devis',
      where: 'devis_id = ?',
      whereArgs: [devisId],
    );
  }

  // Méthode pour générer un numéro de devis unique
  Future<String> generateNumeroDevis() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM devis')) ?? 0;
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final number = (count + 1).toString().padLeft(4, '0');
    return 'DEV-$year$month-$number';
  }
}
