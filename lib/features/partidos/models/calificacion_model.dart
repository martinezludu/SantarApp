import 'package:equatable/equatable.dart';

/// Una calificación de un jugador (voter) a un compañero (target) en un
/// partido. El [voterId] se guarda para evitar votos dobles y saber quién
/// falta, pero NUNCA se muestra en la UI (calificación anónima).
class CalificacionModel extends Equatable {
  final String id;
  final String partidoId;
  final String voterId; // oculto
  final String targetId;
  final int pac;
  final int sho;
  final int pas;
  final int dri;
  final int def;
  final int phy;

  const CalificacionModel({
    required this.id,
    required this.partidoId,
    required this.voterId,
    required this.targetId,
    required this.pac,
    required this.sho,
    required this.pas,
    required this.dri,
    required this.def,
    required this.phy,
  });

  /// Valor de una stat por su clave.
  int stat(String key) => switch (key) {
        'pac' => pac,
        'sho' => sho,
        'pas' => pas,
        'dri' => dri,
        'def' => def,
        'phy' => phy,
        _ => 0,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'partidoId': partidoId,
        'voterId': voterId,
        'targetId': targetId,
        'pac': pac,
        'sho': sho,
        'pas': pas,
        'dri': dri,
        'def': def,
        'phy': phy,
      };

  factory CalificacionModel.fromJson(Map<String, dynamic> json) =>
      CalificacionModel(
        id: json['id'] as String,
        partidoId: json['partidoId'] as String,
        voterId: json['voterId'] as String,
        targetId: json['targetId'] as String,
        pac: json['pac'] as int,
        sho: json['sho'] as int,
        pas: json['pas'] as int,
        dri: json['dri'] as int,
        def: json['def'] as int,
        phy: json['phy'] as int,
      );

  @override
  List<Object?> get props =>
      [id, partidoId, voterId, targetId, pac, sho, pas, dri, def, phy];
}
