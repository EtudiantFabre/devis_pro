class Client {
  final int? id;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;
  final DateTime dateCreation;

  Client({
    this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'date_creation': dateCreation.millisecondsSinceEpoch,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      nom: map['nom'],
      email: map['email'],
      telephone: map['telephone'],
      adresse: map['adresse'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['date_creation']),
    );
  }

  Client copyWith({
    int? id,
    String? nom,
    String? email,
    String? telephone,
    String? adresse,
    DateTime? dateCreation,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
