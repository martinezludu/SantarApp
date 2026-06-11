import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/pronostico_model.dart';
import 'partidos_provider.dart';

SupabaseClient get _db => Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────

class PronosticosNotifier extends Notifier<List<PronosticoModel>> {
  @override
  List<PronosticoModel> build() {
    final sub = _db
        .from('pronosticos')
        .stream(primaryKey: ['id'])
        .listen((data) {
          state = data.map((e) => PronosticoModel.fromJson(e)).toList();
        });
    ref.onDispose(sub.cancel);
    return [];
  }

  Future<void> guardarPronostico({
    required String partidoId,
    required String usuarioId,
    required int golesLocal,
    required int golesVisitante,
  }) async {
    // Block if partido is already finalizado
    final partido = ref
        .read(partidosProvider)
        .where((p) => p.id == partidoId)
        .firstOrNull;
    if (partido?.estaFinalizado == true) return;

    final existing = state
        .where((p) => p.partidoId == partidoId && p.usuarioId == usuarioId)
        .firstOrNull;

    final id = existing?.id ??
        '${partidoId}_${usuarioId}_${DateTime.now().millisecondsSinceEpoch}';

    final data = {
      'id': id,
      'partidoId': partidoId,
      'usuarioId': usuarioId,
      'golesLocal': golesLocal,
      'golesVisitante': golesVisitante,
      'puntosObtenidos': 0,
    };

    await _db.from('pronosticos').upsert(data);
  }
}

final pronosticosProvider =
    NotifierProvider<PronosticosNotifier, List<PronosticoModel>>(
        PronosticosNotifier.new);

// ─────────────────────────────────────────────────────────────────
// Derived providers
// ─────────────────────────────────────────────────────────────────

final pronosticosDePartidoProvider =
    Provider.family<List<PronosticoModel>, String>((ref, partidoId) {
  return ref
      .watch(pronosticosProvider)
      .where((p) => p.partidoId == partidoId)
      .toList();
});

typedef LeaderboardEntry = ({UserModel user, int puntos});

final leaderboardProvider = Provider<List<LeaderboardEntry>>((ref) {
  final pronosticos = ref.watch(pronosticosProvider);
  final members = ref.watch(groupMembersProvider);

  final totals = <String, int>{};
  for (final p in pronosticos) {
    totals[p.usuarioId] = (totals[p.usuarioId] ?? 0) + p.puntosObtenidos;
  }

  return members
      .map((m) => (user: m, puntos: totals[m.id] ?? 0))
      .toList()
    ..sort((a, b) => b.puntos.compareTo(a.puntos));
});

final miPronosticoProvider =
    Provider.family<PronosticoModel?, ({String partidoId, String usuarioId})>(
        (ref, args) {
  return ref
      .watch(pronosticosProvider)
      .where((p) =>
          p.partidoId == args.partidoId && p.usuarioId == args.usuarioId)
      .firstOrNull;
});
