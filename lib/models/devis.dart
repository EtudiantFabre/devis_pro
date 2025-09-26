import 'client.dart';

class Devis {
  final int? id;
  final int clientId;
  final int? entrepriseId;
  final String numero;
  final DateTime dateCreation;
  final DateTime dateEcheance;
  final double total;
  final String statut; // brouillon, envoyé, accepté, refusé
  final String? notes;
  final Client? client;
  final bool tvaApplicable;
  final double? tvaRate; // ex: 20.0
  final String? templateType; // auto_entrepreneur, services, batiment

  Devis({
    this.id,
    required this.clientId,
    this.entrepriseId,
    required this.numero,
    required this.dateCreation,
    required this.dateEcheance,
    required this.total,
    this.statut = 'brouillon',
    this.notes,
    this.client,
    this.tvaApplicable = false,
    this.tvaRate,
    this.templateType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'entreprise_id': entrepriseId,
      'numero': numero,
      'date_creation': dateCreation.millisecondsSinceEpoch,
      'date_echeance': dateEcheance.millisecondsSinceEpoch,
      'total': total,
      'statut': statut,
      'notes': notes,
      'tva_applicable': tvaApplicable ? 1 : 0,
      'tva_rate': tvaRate,
      'template_type': templateType,
    };
  }

  factory Devis.fromMap(Map<String, dynamic> map, {Client? client}) {
    return Devis(
      id: map['id'],
      clientId: map['client_id'],
      entrepriseId: map['entreprise_id'],
      numero: map['numero'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['date_creation']),
      dateEcheance: DateTime.fromMillisecondsSinceEpoch(map['date_echeance']),
      total: map['total'],
      statut: map['statut'],
      notes: map['notes'],
      client: client,
      tvaApplicable: (map['tva_applicable'] ?? 0) == 1,
      tvaRate: map['tva_rate'],
      templateType: map['template_type'],
    );
  }

  Devis copyWith({
    int? id,
    int? clientId,
    int? entrepriseId,
    String? numero,
    DateTime? dateCreation,
    DateTime? dateEcheance,
    double? total,
    String? statut,
    String? notes,
    Client? client,
    bool? tvaApplicable,
    double? tvaRate,
    String? templateType,
  }) {
    return Devis(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      numero: numero ?? this.numero,
      dateCreation: dateCreation ?? this.dateCreation,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      total: total ?? this.total,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      client: client ?? this.client,
      tvaApplicable: tvaApplicable ?? this.tvaApplicable,
      tvaRate: tvaRate ?? this.tvaRate,
      templateType: templateType ?? this.templateType,
    );
  }
}
