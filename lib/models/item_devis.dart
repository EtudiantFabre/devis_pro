import 'produit.dart';

class ItemDevis {
  final int? id;
  final int devisId;
  final int produitId;
  final String nom;
  final String description;
  final double quantite;
  final double prixUnitaire;
  final double total;
  final String? unite;
  final Produit? produit;

  ItemDevis({
    this.id,
    required this.devisId,
    required this.produitId,
    required this.nom,
    required this.description,
    required this.quantite,
    required this.prixUnitaire,
    required this.total,
    this.unite,
    this.produit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'devis_id': devisId,
      'produit_id': produitId,
      'nom': nom,
      'description': description,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'total': total,
      'unite': unite,
    };
  }

  factory ItemDevis.fromMap(Map<String, dynamic> map, {Produit? produit}) {
    return ItemDevis(
      id: map['id'],
      devisId: map['devis_id'],
      produitId: map['produit_id'],
      nom: map['nom'],
      description: map['description'],
      quantite: map['quantite'],
      prixUnitaire: map['prix_unitaire'],
      total: map['total'],
      unite: map['unite'],
      produit: produit,
    );
  }

  ItemDevis copyWith({
    int? id,
    int? devisId,
    int? produitId,
    String? nom,
    String? description,
    double? quantite,
    double? prixUnitaire,
    double? total,
    String? unite,
    Produit? produit,
  }) {
    return ItemDevis(
      id: id ?? this.id,
      devisId: devisId ?? this.devisId,
      produitId: produitId ?? this.produitId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      total: total ?? this.total,
      unite: unite ?? this.unite,
      produit: produit ?? this.produit,
    );
  }
}
