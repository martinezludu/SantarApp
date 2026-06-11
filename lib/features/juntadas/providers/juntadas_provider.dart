import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/expenses/models/expense_model.dart';
import '../../../features/expenses/providers/expenses_provider.dart';
import '../models/juntada_model.dart';

SupabaseClient get _db => Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────

class JuntadasNotifier extends Notifier<List<JuntadaModel>> {
  @override
  List<JuntadaModel> build() {
    final sub = _db
        .from('juntadas')
        .stream(primaryKey: ['id'])
        .order('dateTime', ascending: false)
        .listen((data) {
          state = data
              .map((e) => JuntadaModel.fromJson(e))
              .toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        });
    ref.onDispose(sub.cancel);
    return [];
  }

  Future<void> add(JuntadaModel juntada) async {
    await _db.from('juntadas').insert(juntada.toJson());
  }

  Future<void> update(JuntadaModel juntada) async {
    await _db
        .from('juntadas')
        .update(juntada.toJson())
        .eq('id', juntada.id);
  }

  Future<void> remove(String id) async {
    await _db.from('juntadas').delete().eq('id', id);
  }

  Future<void> setRole(String juntadaId, String role, String userId) async {
    final juntada = state.firstWhere((j) => j.id == juntadaId);
    final updatedRoles = Map<String, String>.from(juntada.roles);
    if (userId.isEmpty) {
      updatedRoles.remove(role);
    } else {
      updatedRoles[role] = userId;
    }
    await update(juntada.copyWith(roles: updatedRoles));
  }

  Future<void> toggleStatus(String juntadaId) async {
    final juntada = state.firstWhere((j) => j.id == juntadaId);
    await update(juntada.copyWith(
      status: juntada.status == JuntadaStatus.planned
          ? JuntadaStatus.finished
          : JuntadaStatus.planned,
    ));
  }
}

final juntadasProvider =
    NotifierProvider<JuntadasNotifier, List<JuntadaModel>>(
        JuntadasNotifier.new);

// ─────────────────────────────────────────────────────────────────
// Derived providers
// ─────────────────────────────────────────────────────────────────

final finishedJuntadasProvider = Provider<List<JuntadaModel>>((ref) {
  return ref
      .watch(juntadasProvider)
      .where((j) => j.status == JuntadaStatus.finished)
      .toList();
});

final juntadaByIdProvider =
    Provider.family<JuntadaModel?, String>((ref, id) {
  return ref.watch(juntadasProvider).where((j) => j.id == id).firstOrNull;
});

final juntadaExpensesProvider =
    Provider.family<List<ExpenseModel>, String>((ref, juntadaId) {
  return ref
      .watch(expensesProvider)
      .where((e) => e.juntadaId == juntadaId)
      .toList();
});
