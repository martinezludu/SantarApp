import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/expense_model.dart';
import '../providers/expenses_provider.dart';
import 'add_expense_screen.dart';
import 'expense_detail_sheet.dart';
import 'widgets/expense_card.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openEdit([ExpenseModel? editing]) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddExpenseScreen(editing: editing)));
  }

  void _showDetail(ExpenseModel expense) {
    showExpenseDetailSheet(context, expense, onEdit: () {
      Navigator.of(context).pop();
      _openEdit(expense);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = ref.watch(expensesProvider);
    final regular = expenses.where((e) => !e.isPayment).toList();
    final total = regular.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gastos 💸'),
            if (regular.isNotEmpty)
              Text('Total: ${fmtAmount(total)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Movimientos'),
            Tab(text: 'Saldos'),
            Tab(text: 'Pagados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _MovimientosTab(onTap: _showDetail),
          const _SaldosTab(),
          _PagadosTab(onTap: _showDetail),
        ],
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton(
              onPressed: () => _openEdit(),
              backgroundColor: AppColors.ember,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 1: Movimientos
// ─────────────────────────────────────────────────────────────────

class _MovimientosTab extends ConsumerWidget {
  final void Function(ExpenseModel) onTap;
  const _MovimientosTab({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses =
        ref.watch(expensesProvider).where((e) => !e.isPayment).toList();

    if (expenses.isEmpty) {
      return _EmptyState(
        emoji: '💸',
        title: 'Sin gastos todavía',
        subtitle: 'Tocá el + para agregar el primero',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: expenses.length,
      separatorBuilder: (_, _s) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          ExpenseCard(expense: expenses[i], onTap: () => onTap(expenses[i])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 2: Saldos
// ─────────────────────────────────────────────────────────────────

class _SaldosTab extends ConsumerWidget {
  const _SaldosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(balancesProvider);
    final settlements = ref.watch(settlementsProvider);
    final members = ref.watch(groupMembersProvider);
    final expenses = ref.watch(expensesProvider);
    final theme = Theme.of(context);

    if (expenses.where((e) => !e.isPayment).isEmpty) {
      return _EmptyState(
        emoji: '⚖️',
        title: 'Todo saldado',
        subtitle: 'Agregá gastos para ver quién le debe a quién',
      );
    }

    final membersWithBalance = members
        .where((m) => (balances[m.id] ?? 0).abs() > 0.01)
        .toList()
      ..sort((a, b) => (balances[b.id] ?? 0).compareTo(balances[a.id] ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Balance', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        ...membersWithBalance
            .map((m) => _BalanceRow(member: m, balance: balances[m.id] ?? 0)),
        if (membersWithBalance.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Todos en cero ✅',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        if (settlements.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('¿Quién le paga a quién?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          ...settlements
              .map((s) => _SettlementRow(settlement: s, members: members)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 3: Pagados
// ─────────────────────────────────────────────────────────────────

class _PagadosTab extends ConsumerWidget {
  final void Function(ExpenseModel) onTap;
  const _PagadosTab({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments =
        ref.watch(expensesProvider).where((e) => e.isPayment).toList();
    final theme = Theme.of(context);

    if (payments.isEmpty) {
      return _EmptyState(
        emoji: '✅',
        title: 'Sin pagos registrados',
        subtitle: 'Usá el botón "Pagar" en Saldos para registrar un pago',
      );
    }

    final total = payments.fold<double>(0, (s, e) => s + e.amount);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: payments.length + 1,
      separatorBuilder: (_, _s) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('${payments.length} pagos registrados',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                Text('Total ${fmtAmount(total)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF34D399),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }
        final p = payments[i - 1];
        return ExpenseCard(expense: p, onTap: () => onTap(p));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Balance row
// ─────────────────────────────────────────────────────────────────

class _BalanceRow extends StatelessWidget {
  final UserModel member;
  final double balance;
  const _BalanceRow({required this.member, required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = balance > 0;
    final color = isPositive ? const Color(0xFF34D399) : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(member.avatarEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.nickname,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(isPositive ? 'le deben' : 'debe',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(fmtAmount(balance.abs()),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Settlement row
// ─────────────────────────────────────────────────────────────────

class _SettlementRow extends ConsumerWidget {
  final Settlement settlement;
  final List<UserModel> members;
  const _SettlementRow({required this.settlement, required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isMyDebt = currentUser?.id == settlement.fromId;

    UserModel? from, to;
    for (final m in members) {
      if (m.id == settlement.fromId) from = m;
      if (m.id == settlement.toId) to = m;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: isMyDebt
            ? AppColors.danger.withValues(alpha: 0.07)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMyDebt
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.ember.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(from?.avatarEmoji ?? '🧑', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(from?.nickname ?? '?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(to?.avatarEmoji ?? '🧑', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(to?.nickname ?? '?',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          Text(fmtAmount(settlement.amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isMyDebt ? AppColors.danger : AppColors.ember)),
          if (isMyDebt) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _registerPayment(ref, to),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF34D399),
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: const Text('Pagar'),
            ),
          ],
        ],
      ),
    );
  }

  void _registerPayment(WidgetRef ref, UserModel? to) {
    ref.read(expensesProvider.notifier).add(ExpenseModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Pago a ${to?.nickname ?? settlement.toId}',
          amount: settlement.amount,
          paidById: settlement.fromId,
          splitAmongIds: [settlement.toId],
          date: DateTime.now(),
          isPayment: true,
        ));
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state helper
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  const _EmptyState(
      {required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
