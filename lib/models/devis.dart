import 'client.dart';

class Devis {
  final int? id;
  final int clientId;
  final String numero;
  final DateTime dateCreation;
  final DateTime dateEcheance;
  final double total;
  final String statut; // brouillon, envoyé, accepté, refusé
  final String? notes;
  final Client? client;

  Devis({
    this.id,
    required this.clientId,
    required this.numero,
    required this.dateCreation,
    required this.dateEcheance,
    required this.total,
    this.statut = 'brouillon',
    this.notes,
    this.client,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'numero': numero,
      'date_creation': dateCreation.millisecondsSinceEpoch,
      'date_echeance': dateEcheance.millisecondsSinceEpoch,
      'total': total,
      'statut': statut,
      'notes': notes,
    };
  }

  factory Devis.fromMap(Map<String, dynamic> map, {Client? client}) {
    return Devis(
      id: map['id'],
      clientId: map['client_id'],
      numero: map['numero'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['date_creation']),
      dateEcheance: DateTime.fromMillisecondsSinceEpoch(map['date_echeance']),
      total: map['total'],
      statut: map['statut'],
      notes: map['notes'],
      client: client,
    );
  }

  Devis copyWith({
    int? id,
    int? clientId,
    String? numero,
    DateTime? dateCreation,
    DateTime? dateEcheance,
    double? total,
    String? statut,
    String? notes,
    Client? client,
  }) {
    return Devis(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      numero: numero ?? this.numero,
      dateCreation: dateCreation ?? this.dateCreation,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      total: total ?? this.total,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      client: client ?? this.client,
    );
  }
}
