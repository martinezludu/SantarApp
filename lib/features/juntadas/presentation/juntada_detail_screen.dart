import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../features/expenses/models/expense_model.dart';
import '../../../features/expenses/presentation/add_expense_screen.dart';
import '../../../features/expenses/presentation/expense_detail_sheet.dart';
import '../../../features/expenses/presentation/widgets/expense_card.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/juntada_model.dart';
import '../providers/juntadas_provider.dart';
import 'add_juntada_screen.dart';

class JuntadaDetailScreen extends ConsumerWidget {
  final String id;
  const JuntadaDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juntada = ref.watch(juntadaByIdProvider(id));
    if (juntada == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Juntada')),
        body: const Center(child: Text('Juntada no encontrada')),
      );
    }

    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider);
    final linkedExpenses = ref.watch(juntadaExpensesProvider(id));
    final participants =
        members.where((m) => juntada.participantIds.contains(m.id)).toList();
    final isFinished = juntada.status == JuntadaStatus.finished;

    return Scaffold(
      appBar: AppBar(
        title: Text(juntada.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => AddJuntadaScreen(editing: juntada))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Header ──
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(juntada.title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    _StatusBadge(status: juntada.status),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: fmtDateLong(juntada.dateTime)),
                if (juntada.placeValue.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: juntada.isRestaurant
                        ? Icons.restaurant_outlined
                        : Icons.home_outlined,
                    text: juntada.isRestaurant
                        ? juntada.placeValue
                        : _hostName(juntada.placeValue, members),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(juntadasProvider.notifier)
                      .toggleStatus(juntada.id),
                  icon: Icon(
                    isFinished
                        ? Icons.replay_outlined
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(isFinished
                      ? 'Reabrir juntada'
                      : 'Finalizar juntada'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isFinished
                        ? theme.colorScheme.surfaceContainerHighest
                        : const Color(0xFF34D399),
                    foregroundColor: isFinished
                        ? theme.colorScheme.onSurface
                        : Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Participantes ──
          Text('Participantes (${participants.length})',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: participants
                .map((m) => Chip(
                      avatar: Text(m.avatarEmoji,
                          style: const TextStyle(fontSize: 16)),
                      label: Text(m.nickname),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // ── Roles ──
          Text('Roles', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...kJuntadaRoles.map((role) => _RoleRow(
                juntadaId: id,
                role: role,
                assignedUserId: juntada.roles[role] ?? '',
                participants: participants,
              )),
          const SizedBox(height: 20),

          // ── Gastos vinculados ──
          Row(
            children: [
              Text('Gastos vinculados', style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(juntadaId: id))),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (linkedExpenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Sin gastos vinculados todavía.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            )
          else
            ...linkedExpenses.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ExpenseCard(
                  expense: e,
                  onTap: () => _showDetail(context, ref, e),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _hostName(String userId, List<UserModel> members) {
    for (final m in members) {
      if (m.id == userId) return 'Casa de ${m.nickname}';
    }
    return 'Casa de...';
  }

  void _showDetail(BuildContext context, WidgetRef ref, ExpenseModel e) {
    showExpenseDetailSheet(context, e, onEdit: () {
      Navigator.of(context).pop();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(editing: e)));
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar juntada'),
        content: const Text('¿Seguro que querés eliminar esta juntada?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(juntadasProvider.notifier).remove(id);
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Role row
// ─────────────────────────────────────────────────────────────────

class _RoleRow extends ConsumerWidget {
  final String juntadaId;
  final String role;
  final String assignedUserId;
  final List<UserModel> participants;

  const _RoleRow({
    required this.juntadaId,
    required this.role,
    required this.assignedUserId,
    required this.participants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final emoji = kRoleEmojis[role] ?? '🎭';

    for (final m in participants) {
      if (m.id == assignedUserId) { break; }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(role,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          DropdownButton<String>(
            value: assignedUserId.isEmpty ? '' : assignedUserId,
            underline: const SizedBox.shrink(),
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            hint: Text('Sin asignar',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text('Sin asignar',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              ...participants.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m.avatarEmoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(m.nickname,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  )),
            ],
            selectedItemBuilder: (_) => [
              Text('Sin asignar',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              ...participants.map((m) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.avatarEmoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(m.nickname, style: theme.textTheme.bodySmall),
                    ],
                  )),
            ],
            onChanged: (v) => ref
                .read(juntadasProvider.notifier)
                .setRole(juntadaId, role, v ?? ''),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final JuntadaStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isFinished = status == JuntadaStatus.finished;
    final color =
        isFinished ? const Color(0xFF34D399) : AppColors.juntadasColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFinished ? '✅ Finalizada' : '🟡 Planificada',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
