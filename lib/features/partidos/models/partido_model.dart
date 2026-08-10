import 'package:equatable/equatable.dart';

/// Las 6 stats estilo FUT. La clave es la que se guarda en la DB.
class StatDef {
  final String key;
  final String abbr; // PAC, SHO...
  final String label; // Nombre largo
  final String emoji;
  const StatDef(this.key, this.abbr, this.label, this.emoji);
}

const kStats = <StatDef>[
  StatDef('pac', 'PAC', 'Velocidad / Físico', '⚡'),
  StatDef('sho', 'SHO', 'Definición', '🎯'),
  StatDef('pas', 'PAS', 'Pase / Visión', '🎁'),
  StatDef('dri', 'DRI', 'Gambeta / Control', '🕺'),
  StatDef('def', 'DEF', 'Marca', '🛡'),
  StatDef('phy', 'PHY', 'Aguante / Choque', '💪'),
];

enum TipoPartido { f5, f7 }

extension TipoPartidoX on TipoPartido {
  String get label => this == TipoPartido.f5 ? 'Fútbol 5' : 'Fútbol 7';
  String get short => this == TipoPartido.f5 ? 'F5' : 'F7';
}

/// Un jugador del plantel de un partido. Puede ser:
/// - miembro del grupo → [id] = userId, [invitado] = false
/// - invitado de afuera → [id] generado, [invitado] = true
/// [nombre] se guarda como snapshot (clave para invitados).
class RosterPlayer extends Equatable {
  final String id;
  final String nombre;
  final bool invitado;

  const RosterPlayer({
    required this.id,
    required this.nombre,
    this.invitado = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'invitado': invitado,
      };

  factory RosterPlayer.fromJson(Map<String, dynamic> json) => RosterPlayer(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        invitado: json['invitado'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, nombre, invitado];
}

class PartidoModel extends Equatable {
  final String id;
  final String titulo; // rival / nombre del partido
  final DateTime dateTime;
  final TipoPartido tipo;
  final int? golesFavor;
  final int? golesContra;
  final List<RosterPlayer> roster;
  final bool cerrado;
  final String creatorId;

  const PartidoModel({
    required this.id,
    required this.titulo,
    required this.dateTime,
    required this.tipo,
    required this.roster,
    this.golesFavor,
    this.golesContra,
    this.cerrado = false,
    this.creatorId = '',
  });

  bool get tieneResultado => golesFavor != null && golesContra != null;

  String get resultadoLabel =>
      tieneResultado ? '$golesFavor - $golesContra' : 'Sin resultado';

  /// V / E / D según el resultado (o null si no hay).
  String? get resultadoSigla {
    if (!tieneResultado) return null;
    if (golesFavor! > golesContra!) return 'V';
    if (golesFavor! < golesContra!) return 'D';
    return 'E';
  }

  PartidoModel copyWith({
    String? titulo,
    DateTime? dateTime,
    TipoPartido? tipo,
    int? golesFavor,
    int? golesContra,
    List<RosterPlayer>? roster,
    bool? cerrado,
    String? creatorId,
    bool clearResultado = false,
  }) =>
      PartidoModel(
        id: id,
        titulo: titulo ?? this.titulo,
        dateTime: dateTime ?? this.dateTime,
        tipo: tipo ?? this.tipo,
        golesFavor: clearResultado ? null : (golesFavor ?? this.golesFavor),
        golesContra: clearResultado ? null : (golesContra ?? this.golesContra),
        roster: roster ?? this.roster,
        cerrado: cerrado ?? this.cerrado,
        creatorId: creatorId ?? this.creatorId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'dateTime': dateTime.toIso8601String(),
        'tipo': tipo.name,
        'golesFavor': golesFavor,
        'golesContra': golesContra,
        'roster': roster.map((r) => r.toJson()).toList(),
        'cerrado': cerrado,
        'creatorId': creatorId,
      };

  factory PartidoModel.fromJson(Map<String, dynamic> json) => PartidoModel(
        id: json['id'] as String,
        titulo: json['titulo'] as String? ?? '',
        dateTime: DateTime.parse(json['dateTime'] as String),
        tipo: TipoPartido.values.byName(json['tipo'] as String? ?? 'f5'),
        golesFavor: json['golesFavor'] as int?,
        golesContra: json['golesContra'] as int?,
        roster: ((json['roster'] as List<dynamic>?) ?? [])
            .map((e) => RosterPlayer.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        cerrado: json['cerrado'] as bool? ?? false,
        creatorId: json['creatorId'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id, titulo, dateTime, tipo, golesFavor,
        golesContra, roster, cerrado, creatorId,
      ];
}
