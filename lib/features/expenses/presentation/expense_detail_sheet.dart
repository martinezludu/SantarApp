import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/expense_model.dart';

/// Abre el bottom sheet de detalle de un gasto.
/// [onEdit] se llama cuando el usuario presiona "Editar".
void showExpenseDetailSheet(
  BuildContext context,
  ExpenseModel expense, {
  VoidCallback? onEdit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExpenseDetailSheet(expense: expense, onEdit: onEdit),
  );
}

class ExpenseDetailSheet extends ConsumerWidget {
  final ExpenseModel expense;
  final VoidCallback? onEdit;

  const ExpenseDetailSheet({super.key, required this.expense, this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider);

    UserModel? paidBy;
    final splitUsers = <UserModel>[];
    for (final m in members) {
      if (m.id == expense.paidById) paidBy = m;
      if (expense.splitAmongIds.contains(m.id)) splitUsers.add(m);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (expense.isPayment)
            _Badge(
              label: '✅ Pago registrado',
              color: const Color(0xFF34D399),
            ),

          // Título y monto
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(expense.description,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              Text(
                fmtAmount(expense.amount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ember,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(fmtDateShort(expense.date),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          _DetailRow(
            label: 'Pagó',
            child: Row(
              children: [
                Text(paidBy?.avatarEmoji ?? '🧑',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(paidBy?.nickname ?? '?',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Dividido entre',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: splitUsers
                  .map((m) => Chip(
                        avatar: Text(m.avatarEmoji,
                            style: const TextStyle(fontSize: 14)),
                        label: Text(m.nickname),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
          if (splitUsers.length > 1) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Parte por persona',
              child: Text(fmtAmount(expense.sharePerPerson),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
              if (!expense.isPayment && onEdit != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(child: child),
      ],
    );
  }
}
