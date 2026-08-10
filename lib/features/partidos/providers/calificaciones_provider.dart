import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/calificacion_model.dart';

SupabaseClient get _db => Supabase.instance.client;

class CalificacionesNotifier extends Notifier<List<CalificacionModel>> {
  @override
  List<CalificacionModel> build() {
    final sub = _db
        .from('calificaciones')
        .stream(primaryKey: ['id'])
        .listen((data) {
          state = data.map((e) => CalificacionModel.fromJson(e)).toList();
        });
    ref.onDispose(sub.cancel);
    return [];
  }

  /// Guarda (o re-guarda) el voto de [voterId] en un partido: borra sus
  /// calificaciones previas de ese partido y vuelve a insertar. Anti-doble.
  Future<void> submitVotos(
    String partidoId,
    String voterId,
    List<CalificacionModel> votos,
  ) async {
    await _db
        .from('calificaciones')
        .delete()
        .eq('partidoId', partidoId)
        .eq('voterId', voterId);
    if (votos.isNotEmpty) {
      await _db
          .from('calificaciones')
          .insert(votos.map((v) => v.toJson()).toList());
    }
  }
}

final calificacionesProvider =
    NotifierProvider<CalificacionesNotifier, List<CalificacionModel>>(
        CalificacionesNotifier.new);

/// Calificaciones de un partido puntual.
final calificacionesDePartidoProvider =
    Provider.family<List<CalificacionModel>, String>((ref, partidoId) {
  return ref
      .watch(calificacionesProvider)
      .where((c) => c.partidoId == partidoId)
      .toList();
});

/// IDs de los que YA votaron en un partido (votantes distintos).
final votantesDePartidoProvider =
    Provider.family<Set<String>, String>((ref, partidoId) {
  return ref
      .watch(calificacionesDePartidoProvider(partidoId))
      .map((c) => c.voterId)
      .toSet();
});
