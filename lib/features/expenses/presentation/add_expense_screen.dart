import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/providers/user_provider.dart';
import '../../juntadas/models/juntada_model.dart';
import '../../juntadas/providers/juntadas_provider.dart';
import '../models/expense_model.dart';
import '../providers/expenses_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel? editing;

  /// Si se abre desde el detalle de una juntada, viene pre-vinculado.
  final String? juntadaId;

  const AddExpenseScreen({super.key, this.editing, this.juntadaId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late String _paidById;
  late Set<String> _splitIds;
  String? _juntadaId;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));

    final e = widget.editing;
    final members = ref.read(groupMembersProvider);
    final currentUser = ref.read(currentUserProvider);

    if (e != null) {
      _descCtrl.text = e.description;
      _amountCtrl.text = e.amount == e.amount.roundToDouble()
          ? e.amount.toInt().toString()
          : e.amount.toStringAsFixed(2);
      _paidById = e.paidById;
      _splitIds = e.splitAmongIds.toSet();
      _juntadaId = e.juntadaId;
    } else {
      _paidById = currentUser?.id ?? members.first.id;
      _splitIds = members.map((m) => m.id).toSet();
      _juntadaId = widget.juntadaId;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final desc = _descCtrl.text.trim();
    final amtStr = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amtStr);

    if (desc.isEmpty) { _snack('Ingresá una descripción'); return; }
    if (amount == null || amount <= 0) { _snack('Ingresá un monto válido'); return; }
    if (_splitIds.isEmpty) { _snack('Seleccioná al menos una persona'); return; }

    final expense = ExpenseModel(
      id: widget.editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: desc,
      amount: amount,
      paidById: _paidById,
      splitAmongIds: _splitIds.toList(),
      date: widget.editing?.date ?? DateTime.now(),
      juntadaId: _juntadaId,
    );

    final notifier = ref.read(expensesProvider.notifier);
    if (widget.editing != null) {
      notifier.update(expense);
    } else {
      notifier.add(expense);
    }

    Navigator.of(context).pop();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider);
    final juntadas = ref.watch(juntadasProvider);
    final allSelected = _splitIds.length == members.length;

    // Juntada vinculada actual
    JuntadaModel? linkedJuntada;
    if (_juntadaId != null) {
      for (final j in juntadas) {
        if (j.id == _juntadaId) { linkedJuntada = j; break; }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing != null ? 'Editar gasto' : 'Nuevo gasto'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 38),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Juntada vinculada (si viene pre-seteada, no se puede quitar) ──
            if (widget.juntadaId != null && linkedJuntada != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.juntadasColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.juntadasColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('🗓', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gasto de juntada',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.juntadasColor)),
                          Text(linkedJuntada.title,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ]
            // ── Selector de juntada opcional ──
            else if (widget.juntadaId == null && juntadas.isNotEmpty) ...[
              Text('Vincular a juntada (opcional)',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _JuntadaSelector(
                juntadas: juntadas,
                selectedId: _juntadaId,
                onChanged: (id) => setState(() => _juntadaId = id),
              ),
              const SizedBox(height: 20),
            ],

            // ── Descripción ──
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Pizza, nafta, hotel...',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: widget.editing == null,
            ),
            const SizedBox(height: 12),

            // ── Monto ──
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),

            // ── ¿Quién pagó? ──
            Text('¿Quién pagó?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                separatorBuilder: (_, _s) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final m = members[i];
                  final sel = m.id == _paidById;
                  return GestureDetector(
                    onTap: () => setState(() => _paidById = m.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 68,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.ember.withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? AppColors.ember : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(m.avatarEmoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 3),
                          Text(m.nickname,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: sel
                                    ? AppColors.ember
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── ¿Entre quiénes? ──
            Row(
              children: [
                Text('¿Entre quiénes?', style: theme.textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _splitIds = allSelected
                        ? {}
                        : members.map((m) => m.id).toSet();
                  }),
                  child: Text(allSelected ? 'Ninguno' : 'Todos'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((m) {
                final sel = _splitIds.contains(m.id);
                return FilterChip(
                  avatar: Text(m.avatarEmoji,
                      style: const TextStyle(fontSize: 16)),
                  label: Text(m.nickname),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) { _splitIds.add(m.id); } else { _splitIds.remove(m.id); }
                  }),
                  selectedColor: AppColors.ember.withValues(alpha: 0.18),
                  checkmarkColor: AppColors.ember,
                );
              }).toList(),
            ),

            // ── Preview ──
            if (_splitIds.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildPreview(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final amount = double.tryParse(
            _amountCtrl.text.trim().replaceAll(',', '.')) ??
        0;
    if (amount <= 0) return const SizedBox.shrink();
    final share = amount / _splitIds.length;
    final shareStr = share == share.roundToDouble()
        ? '\$${share.toInt()}'
        : '\$${share.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ember.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.ember.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.ember, size: 18),
          const SizedBox(width: 10),
          Text('$shareStr por persona  ·  ${_splitIds.length} personas',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.ember)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Selector de juntada
// ─────────────────────────────────────────────────────────────────

class _JuntadaSelector extends StatelessWidget {
  final List<JuntadaModel> juntadas;
  final String? selectedId;
  final void Function(String?) onChanged;

  const _JuntadaSelector({
    required this.juntadas,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedId,
          hint: Text('Sin vincular',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('Sin vincular',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            ...juntadas.map((j) => DropdownMenuItem(
                  value: j.id,
                  child: Row(
                    children: [
                      Text(
                          j.status == JuntadaStatus.finished ? '✅' : '🟡',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(j.title,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
