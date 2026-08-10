import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/user_provider.dart';
import '../models/calificacion_model.dart';
import '../models/partido_model.dart';
import 'calificaciones_provider.dart';
import 'partidos_provider.dart';

/// Carta estilo FUT de un jugador, calculada sobre TODO el histórico.
class Carta {
  final String id;
  final String nombre;
  final bool invitado;
  final String avatarEmoji;

  /// Cada stat en escala /100 (promedio histórico 1-5 → x20).
  final Map<String, int> stats100;
  final int ovr; // 0 si no tiene datos
  final int partidosCalificados;
  final int motmCount;

  const Carta({
    required this.id,
    required this.nombre,
    required this.invitado,
    required this.avatarEmoji,
    required this.stats100,
    required this.ovr,
    required this.partidosCalificados,
    required this.motmCount,
  });

  bool get tieneDatos => ovr > 0;

  /// Posición derivada de la stat más fuerte (solo cosmético).
  String get posicion {
    if (!tieneDatos) return '—';
    var bestKey = kStats.first.key;
    var bestVal = -1;
    for (final s in kStats) {
      final v = stats100[s.key] ?? 0;
      if (v > bestVal) {
        bestVal = v;
        bestKey = s.key;
      }
    }
    return switch (bestKey) {
      'pac' => 'EXT',
      'sho' => 'DEL',
      'pas' => 'MED',
      'dri' => 'MED',
      'def' => 'DEF',
      'phy' => 'DEF',
      _ => 'MED',
    };
  }

  /// Categoría de la carta según OVR (para el color de fondo).
  CartaTier get tier {
    if (ovr >= 85) return CartaTier.icon;
    if (ovr >= 75) return CartaTier.gold;
    if (ovr >= 65) return CartaTier.silver;
    return CartaTier.bronze;
  }
}

enum CartaTier { bronze, silver, gold, icon }

int _to100(double avg5) => (avg5 / 5 * 100).round();

/// Promedio por stat (1-5) de las calificaciones que apuntan a [targetId].
Map<String, double> _avgStats(List<CalificacionModel> califs) {
  final result = <String, double>{};
  for (final s in kStats) {
    if (califs.isEmpty) {
      result[s.key] = 0;
      continue;
    }
    final sum = califs.fold<int>(0, (acc, c) => acc + c.stat(s.key));
    result[s.key] = sum / califs.length;
  }
  return result;
}

/// MOTM de un partido = jugador con mayor promedio de sus 6 stats en ESE
/// partido. Devuelve el targetId ganador, o null si no hay calificaciones.
String? motmDePartido(List<CalificacionModel> califsPartido) {
  if (califsPartido.isEmpty) return null;
  final porTarget = <String, List<CalificacionModel>>{};
  for (final c in califsPartido) {
    porTarget.putIfAbsent(c.targetId, () => []).add(c);
  }
  String? best;
  var bestAvg = -1.0;
  porTarget.forEach((target, califs) {
    final avg = _avgStats(califs);
    final mean =
        kStats.fold<double>(0, (acc, s) => acc + (avg[s.key] ?? 0)) /
            kStats.length;
    if (mean > bestAvg) {
      bestAvg = mean;
      best = target;
    }
  });
  return best;
}

/// Provider derivado: una carta por cada jugador conocido (miembros del grupo
/// + invitados que aparecieron en algún plantel).
final cartasProvider = Provider<List<Carta>>((ref) {
  final partidos = ref.watch(partidosProvider);
  // Se ignora cualquier auto-voto (targetId == voterId): nadie se califica
  // a sí mismo. La UI ya lo impide; esto es defensa en profundidad.
  final califs = ref
      .watch(calificacionesProvider)
      .where((c) => c.voterId != c.targetId)
      .toList();
  final members = ref.watch(groupMembersProvider);

  // Nombre + emoji por id: miembros del grupo primero, luego snapshots de roster.
  final nombre = <String, String>{};
  final emoji = <String, String>{};
  final esInvitado = <String, bool>{};
  for (final m in members) {
    nombre[m.id] = m.nickname;
    emoji[m.id] = m.avatarEmoji;
    esInvitado[m.id] = false;
  }
  for (final p in partidos) {
    for (final r in p.roster) {
      nombre.putIfAbsent(r.id, () => r.nombre);
      esInvitado.putIfAbsent(r.id, () => r.invitado);
      if (r.invitado) emoji.putIfAbsent(r.id, () => '⚽');
    }
  }

  // MOTM count por jugador.
  final motmCount = <String, int>{};
  for (final p in partidos) {
    final delPartido = califs.where((c) => c.partidoId == p.id).toList();
    final motm = motmDePartido(delPartido);
    if (motm != null) motmCount[motm] = (motmCount[motm] ?? 0) + 1;
  }

  final cartas = <Carta>[];
  for (final id in nombre.keys) {
    final mias = califs.where((c) => c.targetId == id).toList();
    final avg = _avgStats(mias);
    final stats100 = <String, int>{
      for (final s in kStats) s.key: _to100(avg[s.key] ?? 0),
    };
    final ovr = mias.isEmpty
        ? 0
        : (kStats.fold<int>(0, (acc, s) => acc + (stats100[s.key] ?? 0)) /
                kStats.length)
            .round();
    final partidosCal =
        mias.map((c) => c.partidoId).toSet().length;

    cartas.add(Carta(
      id: id,
      nombre: nombre[id] ?? 'Jugador',
      invitado: esInvitado[id] ?? false,
      avatarEmoji: emoji[id] ?? '🧑',
      stats100: stats100,
      ovr: ovr,
      partidosCalificados: partidosCal,
      motmCount: motmCount[id] ?? 0,
    ));
  }

  cartas.sort((a, b) => b.ovr.compareTo(a.ovr));
  return cartas;
});

final cartaByIdProvider = Provider.family<Carta?, String>((ref, id) {
  return ref.watch(cartasProvider).where((c) => c.id == id).firstOrNull;
});
