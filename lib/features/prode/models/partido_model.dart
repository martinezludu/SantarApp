import 'package:equatable/equatable.dart';

enum EstadoPartido { proximamente, enCurso, finalizado }

class PartidoModel extends Equatable {
  final String id;
  final String equipoLocal;
  final String equipoVisitante;
  final DateTime fechaHora;
  final int? golesLocalReal;
  final int? golesVisitanteReal;
  final EstadoPartido estado;
  final String grupo; // 'A'..'L', 'Dieciseisavos', 'Octavos', 'Cuartos', 'Semifinal', 'Tercer Puesto', 'Final'
  final int orden; // for sorting within group

  const PartidoModel({
    required this.id,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.fechaHora,
    this.golesLocalReal,
    this.golesVisitanteReal,
    required this.estado,
    required this.grupo,
    required this.orden,
  });

  bool get estaFinalizado => estado == EstadoPartido.finalizado;
  // grupo is 'Grupo A'..'Grupo L' for group stage, otherwise knockout
  bool get esFase => !grupo.startsWith('Grupo ');

  PartidoModel copyWith({
    String? equipoLocal,
    String? equipoVisitante,
    int? golesLocalReal,
    int? golesVisitanteReal,
    EstadoPartido? estado,
    bool clearGoles = false,
  }) =>
      PartidoModel(
        id: id,
        equipoLocal: equipoLocal ?? this.equipoLocal,
        equipoVisitante: equipoVisitante ?? this.equipoVisitante,
        fechaHora: fechaHora,
        golesLocalReal: clearGoles ? null : (golesLocalReal ?? this.golesLocalReal),
        golesVisitanteReal: clearGoles ? null : (golesVisitanteReal ?? this.golesVisitanteReal),
        estado: estado ?? this.estado,
        grupo: grupo,
        orden: orden,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipoLocal': equipoLocal,
        'equipoVisitante': equipoVisitante,
        'fechaHora': fechaHora.toIso8601String(),
        'golesLocalReal': golesLocalReal,
        'golesVisitanteReal': golesVisitanteReal,
        'estado': estado.name,
        'grupo': grupo,
        'orden': orden,
      };

  factory PartidoModel.fromJson(Map<String, dynamic> json) => PartidoModel(
        id: json['id'] as String,
        equipoLocal: json['equipoLocal'] as String,
        equipoVisitante: json['equipoVisitante'] as String,
        fechaHora: DateTime.parse(json['fechaHora'] as String),
        golesLocalReal: json['golesLocalReal'] as int?,
        golesVisitanteReal: json['golesVisitanteReal'] as int?,
        estado: EstadoPartido.values.byName(json['estado'] as String),
        grupo: json['grupo'] as String,
        orden: json['orden'] as int,
      );

  @override
  List<Object?> get props => [
        id, equipoLocal, equipoVisitante, fechaHora,
        golesLocalReal, golesVisitanteReal, estado, grupo, orden,
      ];
}
