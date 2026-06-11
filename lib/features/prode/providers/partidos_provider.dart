import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/partido_model.dart';
import '../models/pronostico_model.dart';

SupabaseClient get _db => Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────
// Bracket maps  (based on the official SQL fixture)
// ─────────────────────────────────────────────────────────────────

const _allGroups = [
  'Grupo A', 'Grupo B', 'Grupo C', 'Grupo D', 'Grupo E', 'Grupo F',
  'Grupo G', 'Grupo H', 'Grupo I', 'Grupo J', 'Grupo K', 'Grupo L',
];

// grupo → (r32Id, slot) — slot 1 = local, 2 = visitante
const Map<String, (String, int)> _groupFirst = {
  'Grupo A': ('m26-p79', 1),
  'Grupo B': ('m26-p85', 1),
  'Grupo C': ('m26-p76', 1),
  'Grupo D': ('m26-p81', 1),
  'Grupo E': ('m26-p74', 1),
  'Grupo F': ('m26-p75', 1),
  'Grupo G': ('m26-p82', 1),
  'Grupo H': ('m26-p84', 1),
  'Grupo I': ('m26-p77', 1),
  'Grupo J': ('m26-p86', 1),
  'Grupo K': ('m26-p87', 1),
  'Grupo L': ('m26-p80', 1),
};

const Map<String, (String, int)> _groupSecond = {
  'Grupo A': ('m26-p73', 1),
  'Grupo B': ('m26-p73', 2),
  'Grupo C': ('m26-p75', 2),
  'Grupo D': ('m26-p88', 1),
  'Grupo E': ('m26-p78', 1),
  'Grupo F': ('m26-p76', 2),
  'Grupo G': ('m26-p88', 2),
  'Grupo H': ('m26-p86', 2),
  'Grupo I': ('m26-p78', 2),
  'Grupo J': ('m26-p84', 2),
  'Grupo K': ('m26-p83', 1),
  'Grupo L': ('m26-p83', 2),
};

// 8 visitante slots for best 3rd-place teams (assigned after all groups done)
const _thirdPlaceSlots = [
  ('m26-p74', 2), ('m26-p77', 2), ('m26-p79', 2), ('m26-p80', 2),
  ('m26-p81', 2), ('m26-p82', 2), ('m26-p85', 2), ('m26-p87', 2),
];

// winner of matchId → (nextMatchId, slot)
const Map<String, (String, int)> _knockoutNext = {
  // Dieciseisavos → Octavos
  'm26-p73': ('m26-p90', 1), 'm26-p74': ('m26-p89', 1),
  'm26-p75': ('m26-p90', 2), 'm26-p76': ('m26-p91', 1),
  'm26-p77': ('m26-p89', 2), 'm26-p78': ('m26-p91', 2),
  'm26-p79': ('m26-p92', 1), 'm26-p80': ('m26-p92', 2),
  'm26-p81': ('m26-p94', 1), 'm26-p82': ('m26-p94', 2),
  'm26-p83': ('m26-p93', 1), 'm26-p84': ('m26-p93', 2),
  'm26-p85': ('m26-p96', 1), 'm26-p86': ('m26-p95', 1),
  'm26-p87': ('m26-p96', 2), 'm26-p88': ('m26-p95', 2),
  // Octavos → Cuartos
  'm26-p89': ('m26-p97', 1),  'm26-p90': ('m26-p97', 2),
  'm26-p91': ('m26-p99', 1),  'm26-p92': ('m26-p99', 2),
  'm26-p93': ('m26-p98', 1),  'm26-p94': ('m26-p98', 2),
  'm26-p95': ('m26-p100', 1), 'm26-p96': ('m26-p100', 2),
  // Cuartos → Semifinal
  'm26-p97':  ('m26-p101', 1), 'm26-p98':  ('m26-p101', 2),
  'm26-p99':  ('m26-p102', 1), 'm26-p100': ('m26-p102', 2),
  // Semifinal → Final
  'm26-p101': ('m26-p104', 1), 'm26-p102': ('m26-p104', 2),
};

// ─────────────────────────────────────────────────────────────────
// Standings helpers
// ─────────────────────────────────────────────────────────────────

class TeamStat {
  int pts = 0, gf = 0, ga = 0, pj = 0;
  int get gd => gf - ga;
}

/// Derives teams from actual match data — no hardcoded team lists.
Map<String, TeamStat> computeGroupStats(List<PartidoModel> all, String grupo) {
  final stats = <String, TeamStat>{};
  final groupMatches = all.where((p) => p.grupo == grupo).toList();

  for (final m in groupMatches) {
    stats.putIfAbsent(m.equipoLocal, () => TeamStat());
    stats.putIfAbsent(m.equipoVisitante, () => TeamStat());
  }

  for (final m in groupMatches.where((p) => p.estaFinalizado)) {
    final gl = m.golesLocalReal!;
    final gv = m.golesVisitanteReal!;
    stats[m.equipoLocal]!.gf += gl;
    stats[m.equipoLocal]!.ga += gv;
    stats[m.equipoLocal]!.pj++;
    stats[m.equipoVisitante]!.gf += gv;
    stats[m.equipoVisitante]!.ga += gl;
    stats[m.equipoVisitante]!.pj++;
    if (gl > gv) {
      stats[m.equipoLocal]!.pts += 3;
    } else if (gl == gv) {
      stats[m.equipoLocal]!.pts += 1;
      stats[m.equipoVisitante]!.pts += 1;
    } else {
      stats[m.equipoVisitante]!.pts += 3;
    }
  }
  return stats;
}

List<String> sortedGroupStandings(List<PartidoModel> all, String grupo) {
  final stats = computeGroupStats(all, grupo);
  return stats.keys.toList()
    ..sort((a, b) {
      final sa = stats[a]!, sb = stats[b]!;
      if (sb.pts != sa.pts) return sb.pts.compareTo(sa.pts);
      if (sb.gd != sa.gd) return sb.gd.compareTo(sa.gd);
      return sb.gf.compareTo(sa.gf);
    });
}

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────

class PartidosNotifier extends Notifier<List<PartidoModel>> {
  @override
  List<PartidoModel> build() {
    _setup();
    return [];
  }

  Future<void> _setup() async {
    // Fixture is seeded via SQL script — just subscribe to the stream
    final sub = _db
        .from('partidos')
        .stream(primaryKey: ['id'])
        .order('orden')
        .listen((data) {
          state = data.map((e) => PartidoModel.fromJson(e)).toList()
            ..sort((a, b) => a.orden.compareTo(b.orden));
        });
    ref.onDispose(sub.cancel);
  }

  Future<void> updateEstado(String id, EstadoPartido estado) async {
    await _db.from('partidos').update({'estado': estado.name}).eq('id', id);
  }

  Future<void> cargarResultadoYFinalizar(
      String id, int golesLocal, int golesVisitante) async {
    // 1. Save result
    await _db.from('partidos').update({
      'golesLocalReal': golesLocal,
      'golesVisitanteReal': golesVisitante,
      'estado': EstadoPartido.finalizado.name,
    }).eq('id', id);

    // 2. Recalculate pronostico points
    final pronosData =
        await _db.from('pronosticos').select().eq('partidoId', id);
    final partido = state.firstWhere((p) => p.id == id).copyWith(
      golesLocalReal: golesLocal,
      golesVisitanteReal: golesVisitante,
      estado: EstadoPartido.finalizado,
    );
    for (final raw in pronosData as List) {
      final prono = PronosticoModel.fromJson(raw as Map<String, dynamic>);
      final pts = calcularPuntos(partido, prono);
      await _db
          .from('pronosticos')
          .update({'puntosObtenidos': pts})
          .eq('id', prono.id);
    }

    // 3. Build updated in-memory list for bracket logic
    final updatedAll = [
      for (final p in state) if (p.id == id) partido else p
    ];

    // 4. Auto-advance bracket
    await _tryAutoAdvance(partido, updatedAll);
  }

  Future<void> updateEquipos(String id, String local, String visitante) async {
    await _db.from('partidos').update({
      'equipoLocal': local,
      'equipoVisitante': visitante,
    }).eq('id', id);
  }

  // ── Bracket advance ───────────────────────────────────────────

  Future<void> _tryAutoAdvance(
      PartidoModel finalized, List<PartidoModel> all) async {
    if (finalized.grupo.startsWith('Grupo ')) {
      await _tryAdvanceGroup(all, finalized.grupo);
    } else {
      await _tryAdvanceKnockout(finalized);
    }
  }

  Future<void> _tryAdvanceGroup(
      List<PartidoModel> all, String grupo) async {
    final groupMatches = all.where((p) => p.grupo == grupo).toList();
    // Each group has 6 matches (4 teams, C(4,2) = 6)
    if (groupMatches.length < 6 ||
        !groupMatches.every((p) => p.estaFinalizado)) {
      return;
    }

    final standings = sortedGroupStandings(all, grupo);
    if (standings.length < 2) return;

    final fd = _groupFirst[grupo]!;
    final sd = _groupSecond[grupo]!;
    await _setSlot(fd.$1, fd.$2, standings[0]);
    await _setSlot(sd.$1, sd.$2, standings[1]);

    await _tryAssignBest3rd(all);
  }

  Future<void> _tryAssignBest3rd(List<PartidoModel> all) async {
    // Only run when ALL 12 groups are complete
    for (final grupo in _allGroups) {
      final gm = all.where((p) => p.grupo == grupo).toList();
      if (gm.length < 6 || !gm.every((p) => p.estaFinalizado)) return;
    }

    // Collect all 3rd-place teams ranked by pts → GD → GF
    final thirds = <({String team, int pts, int gd, int gf})>[];
    for (final grupo in _allGroups) {
      final standings = sortedGroupStandings(all, grupo);
      if (standings.length >= 3) {
        final stats = computeGroupStats(all, grupo);
        final t = standings[2];
        thirds.add((
          team: t,
          pts: stats[t]!.pts,
          gd: stats[t]!.gd,
          gf: stats[t]!.gf,
        ));
      }
    }

    thirds.sort((a, b) {
      if (b.pts != a.pts) return b.pts.compareTo(a.pts);
      if (b.gd != a.gd) return b.gd.compareTo(a.gd);
      return b.gf.compareTo(a.gf);
    });

    // Best 8 → assigned to the 8 3rd-place slots (visitante side)
    final best8 = thirds.take(8).map((t) => t.team).toList();
    for (int i = 0; i < best8.length; i++) {
      await _setSlot(_thirdPlaceSlots[i].$1, _thirdPlaceSlots[i].$2, best8[i]);
    }
  }

  Future<void> _tryAdvanceKnockout(PartidoModel finalized) async {
    final winner = _winner(finalized);
    if (winner == null) return; // draw → admin assigns manually

    final next = _knockoutNext[finalized.id];
    if (next != null) {
      await _setSlot(next.$1, next.$2, winner);
    }

    // Semifinal loser → Tercer Puesto
    if (finalized.id == 'm26-p101' || finalized.id == 'm26-p102') {
      final loser = _loser(finalized);
      if (loser != null) {
        final slot = finalized.id == 'm26-p101' ? 1 : 2;
        await _setSlot('m26-p103', slot, loser);
      }
    }
  }

  Future<void> _setSlot(String matchId, int slot, String team) async {
    final field = slot == 1 ? 'equipoLocal' : 'equipoVisitante';
    await _db.from('partidos').update({field: team}).eq('id', matchId);
  }

  String? _winner(PartidoModel m) {
    final gl = m.golesLocalReal, gv = m.golesVisitanteReal;
    if (gl == null || gv == null) return null;
    if (gl > gv) return m.equipoLocal;
    if (gv > gl) return m.equipoVisitante;
    return null; // draw → penales, admin asigna manualmente
  }

  String? _loser(PartidoModel m) {
    final gl = m.golesLocalReal, gv = m.golesVisitanteReal;
    if (gl == null || gv == null) return null;
    if (gl > gv) return m.equipoVisitante;
    if (gv > gl) return m.equipoLocal;
    return null;
  }
}

final partidosProvider =
    NotifierProvider<PartidosNotifier, List<PartidoModel>>(
        PartidosNotifier.new);

// ─────────────────────────────────────────────────────────────────
// UI providers
// ─────────────────────────────────────────────────────────────────

typedef GroupStandingEntry = ({String team, TeamStat stat});

final groupStandingsProvider =
    Provider.family<List<GroupStandingEntry>, String>((ref, grupo) {
  final partidos = ref.watch(partidosProvider);
  final stats = computeGroupStats(partidos, grupo);
  final sorted = sortedGroupStandings(partidos, grupo);
  return sorted.map((t) => (team: t, stat: stats[t]!)).toList();
});
