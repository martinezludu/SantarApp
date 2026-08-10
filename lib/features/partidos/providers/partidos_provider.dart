import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/partido_model.dart';

SupabaseClient get _db => Supabase.instance.client;

class PartidosNotifier extends Notifier<List<PartidoModel>> {
  @override
  List<PartidoModel> build() {
    final sub = _db
        .from('partidos')
        .stream(primaryKey: ['id'])
        .order('dateTime', ascending: false)
        .listen((data) {
          state = data.map((e) => PartidoModel.fromJson(e)).toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        });
    ref.onDispose(sub.cancel);
    return [];
  }

  Future<void> add(PartidoModel partido) async {
    await _db.from('partidos').insert(partido.toJson());
  }

  Future<void> update(PartidoModel partido) async {
    await _db.from('partidos').update(partido.toJson()).eq('id', partido.id);
  }

  Future<void> remove(String id) async {
    await _db.from('calificaciones').delete().eq('partidoId', id);
    await _db.from('partidos').delete().eq('id', id);
  }

  Future<void> toggleCerrado(String partidoId) async {
    final p = state.firstWhere((x) => x.id == partidoId);
    await update(p.copyWith(cerrado: !p.cerrado));
  }
}

final partidosProvider =
    NotifierProvider<PartidosNotifier, List<PartidoModel>>(
        PartidosNotifier.new);

final partidoByIdProvider =
    Provider.family<PartidoModel?, String>((ref, id) {
  return ref.watch(partidosProvider).where((p) => p.id == id).firstOrNull;
});
