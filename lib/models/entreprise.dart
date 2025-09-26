class Entreprise {
  final int? id;
  final String nom;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? siret;
  final String? tvaIntracom;
  final String? logoPath;
  final DateTime dateCreation;

  Entreprise({
    this.id,
    required this.nom,
    this.email,
    this.telephone,
    this.adresse,
    this.siret,
    this.tvaIntracom,
    this.logoPath,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'siret': siret,
      'tva_intracom': tvaIntracom,
      'logo_path': logoPath,
      'date_creation': dateCreation.millisecondsSinceEpoch,
    };
  }

  factory Entreprise.fromMap(Map<String, dynamic> map) {
    return Entreprise(
      id: map['id'],
      nom: map['nom'],
      email: map['email'],
      telephone: map['telephone'],
      adresse: map['adresse'],
      siret: map['siret'],
      tvaIntracom: map['tva_intracom'],
      logoPath: map['logo_path'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['date_creation']),
    );
  }

  Entreprise copyWith({
    int? id,
    String? nom,
    String? email,
    String? telephone,
    String? adresse,
    String? siret,
    String? tvaIntracom,
    String? logoPath,
    DateTime? dateCreation,
  }) {
    return Entreprise(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      siret: siret ?? this.siret,
      tvaIntracom: tvaIntracom ?? this.tvaIntracom,
      logoPath: logoPath ?? this.logoPath,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}


