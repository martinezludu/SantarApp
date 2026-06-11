import 'package:equatable/equatable.dart';

enum JuntadaStatus { planned, finished }

const kJuntadaRoles = [
  'Asador',
  'Ponedor de casa',
  'Comprador',
  'Lavador',
  'Pagador',
];

const kRoleEmojis = {
  'Asador': '🔥',
  'Ponedor de casa': '🏠',
  'Comprador': '🛒',
  'Lavador': '🧹',
  'Pagador': '💵',
};

class JuntadaModel extends Equatable {
  final String id;
  final String title;
  final DateTime dateTime;
  final JuntadaStatus status;
  final List<String> participantIds;
  final String creatorId;

  // Lugar: isRestaurant=true → restaurantName libre
  //        isRestaurant=false → userId del anfitrión
  final bool isRestaurant;
  final String placeValue;

  // Roles: Map<nombreRol, userId> — string vacío = sin asignar
  final Map<String, String> roles;

  const JuntadaModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.status,
    required this.participantIds,
    required this.creatorId,
    this.isRestaurant = true,
    this.placeValue = '',
    this.roles = const {},
  });

  String get statusLabel =>
      status == JuntadaStatus.planned ? 'Planificada' : 'Finalizada';

  JuntadaModel copyWith({
    String? title,
    DateTime? dateTime,
    JuntadaStatus? status,
    List<String>? participantIds,
    String? creatorId,
    bool? isRestaurant,
    String? placeValue,
    Map<String, String>? roles,
  }) =>
      JuntadaModel(
        id: id,
        title: title ?? this.title,
        dateTime: dateTime ?? this.dateTime,
        status: status ?? this.status,
        participantIds: participantIds ?? this.participantIds,
        creatorId: creatorId ?? this.creatorId,
        isRestaurant: isRestaurant ?? this.isRestaurant,
        placeValue: placeValue ?? this.placeValue,
        roles: roles ?? this.roles,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'status': status.name,
        'participantIds': participantIds,
        'creatorId': creatorId,
        'isRestaurant': isRestaurant,
        'placeValue': placeValue,
        'roles': roles,
      };

  factory JuntadaModel.fromJson(Map<String, dynamic> json) => JuntadaModel(
        id: json['id'] as String,
        title: json['title'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        status: JuntadaStatus.values.byName(
            json['status'] as String? ?? 'planned'),
        participantIds:
            (json['participantIds'] as List<dynamic>).cast<String>(),
        creatorId: json['creatorId'] as String,
        isRestaurant: json['isRestaurant'] as bool? ?? true,
        placeValue: json['placeValue'] as String? ?? '',
        roles: Map<String, String>.from(
            (json['roles'] as Map<dynamic, dynamic>? ?? {})),
      );

  @override
  List<Object?> get props => [
        id, title, dateTime, status, participantIds,
        creatorId, isRestaurant, placeValue, roles,
      ];
}
