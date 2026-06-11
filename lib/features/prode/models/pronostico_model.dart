import 'package:equatable/equatable.dart';
import 'partido_model.dart';

class PronosticoModel extends Equatable {
  final String id;
  final String partidoId;
  final String usuarioId;
  final int golesLocal;
  final int golesVisitante;
  final int puntosObtenidos;

  const PronosticoModel({
    required this.id,
    required this.partidoId,
    required this.usuarioId,
    required this.golesLocal,
    required this.golesVisitante,
    this.puntosObtenidos = 0,
  });

  PronosticoModel copyWith({int? puntosObtenidos}) => PronosticoModel(
        id: id,
        partidoId: partidoId,
        usuarioId: usuarioId,
        golesLocal: golesLocal,
        golesVisitante: golesVisitante,
        puntosObtenidos: puntosObtenidos ?? this.puntosObtenidos,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'partidoId': partidoId,
        'usuarioId': usuarioId,
        'golesLocal': golesLocal,
        'golesVisitante': golesVisitante,
        'puntosObtenidos': puntosObtenidos,
      };

  factory PronosticoModel.fromJson(Map<String, dynamic> json) =>
      PronosticoModel(
        id: json['id'] as String,
        partidoId: json['partidoId'] as String,
        usuarioId: json['usuarioId'] as String,
        golesLocal: json['golesLocal'] as int,
        golesVisitante: json['golesVisitante'] as int,
        puntosObtenidos: json['puntosObtenidos'] as int? ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, partidoId, usuarioId, golesLocal, golesVisitante, puntosObtenidos];
}

int calcularPuntos(PartidoModel partido, PronosticoModel prono) {
  if (!partido.estaFinalizado) return 0;
  final rl = partido.golesLocalReal;
  final rv = partido.golesVisitanteReal;
  if (rl == null || rv == null) return 0;
  if (prono.golesLocal == rl && prono.golesVisitante == rv) return 3;
  final pronoSign = (prono.golesLocal - prono.golesVisitante).sign;
  final realSign = (rl - rv).sign;
  if (pronoSign == realSign) return 1;
  return 0;
}
