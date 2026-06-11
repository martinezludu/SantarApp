import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense_model.dart';

SupabaseClient get _db => Supabase.instance.client;

// ────────────────────────────────────────────────────────────────
// Settlement
// ────────────────────────────────────────────────────────────────

class Settlement {
  final String fromId;
  final String toId;
  final double amount;
  const Settlement(
      {required this.fromId, required this.toId, required this.amount});
}

// ────────────────────────────────────────────────────────────────
// Expenses notifier
// ────────────────────────────────────────────────────────────────

class ExpensesNotifier extends Notifier<List<ExpenseModel>> {
  @override
  List<ExpenseModel> build() {
    final sub = _db
        .from('expenses')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .listen((data) {
          state = data
              .map((e) => ExpenseModel.fromJson(e))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        });
    ref.onDispose(sub.cancel);
    return [];
  }

  Future<void> add(ExpenseModel expense) async {
    await _db.from('expenses').insert(expense.toJson());
  }

  Future<void> remove(String id) async {
    await _db.from('expenses').delete().eq('id', id);
  }

  Future<void> update(ExpenseModel expense) async {
    await _db
        .from('expenses')
        .update(expense.toJson())
        .eq('id', expense.id);
  }
}

final expensesProvider =
    NotifierProvider<ExpensesNotifier, List<ExpenseModel>>(
        ExpensesNotifier.new);

// ────────────────────────────────────────────────────────────────
// Balance computation
// positive balance  → others owe you
// negative balance  → you owe others
// ────────────────────────────────────────────────────────────────

final balancesProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final balances = <String, double>{};
  for (final e in expenses) {
    if (e.splitAmongIds.isEmpty) continue;
    final share = e.amount / e.splitAmongIds.length;
    balances[e.paidById] = (balances[e.paidById] ?? 0) + e.amount;
    for (final uid in e.splitAmongIds) {
      balances[uid] = (balances[uid] ?? 0) - share;
    }
  }
  return balances;
});

final settlementsProvider = Provider<List<Settlement>>((ref) {
  final balances = ref.watch(balancesProvider);
  return _simplifyDebts(balances);
});

List<Settlement> _simplifyDebts(Map<String, double> balances) {
  final credAmt = <String, double>{};
  final debtAmt = <String, double>{};

  for (final e in balances.entries) {
    if (e.value > 0.01) credAmt[e.key] = e.value;
    if (e.value < -0.01) debtAmt[e.key] = e.value.abs();
  }

  final c = {
    for (final e in (credAmt.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))))
      e.key: e.value
  };
  final d = {
    for (final e in (debtAmt.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))))
      e.key: e.value
  };

  final result = <Settlement>[];

  while (c.isNotEmpty && d.isNotEmpty) {
    final creditor = c.keys.first;
    final debtor = d.keys.first;
    final pay = min(c[creditor]!, d[debtor]!);

    result.add(Settlement(fromId: debtor, toId: creditor, amount: pay));

    c[creditor] = c[creditor]! - pay;
    d[debtor] = d[debtor]! - pay;

    if (c[creditor]! < 0.01) c.remove(creditor);
    if (d[debtor]! < 0.01) d.remove(debtor);
  }

  return result;
}
