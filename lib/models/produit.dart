class Produit {
  final int? id;
  final String nom;
  final String description;
  final double prixUnitaire;
  final String? unite; // pièce, heure, kg, etc.
  final DateTime dateCreation;

  Produit({
    this.id,
    required this.nom,
    required this.description,
    required this.prixUnitaire,
    this.unite,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'prix_unitaire': prixUnitaire,
      'unite': unite,
      'date_creation': dateCreation.millisecondsSinceEpoch,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'],
      nom: map['nom'],
      description: map['description'],
      prixUnitaire: map['prix_unitaire'],
      unite: map['unite'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['date_creation']),
    );
  }

  Produit copyWith({
    int? id,
    String? nom,
    String? description,
    double? prixUnitaire,
    String? unite,
    DateTime? dateCreation,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      unite: unite ?? this.unite,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
