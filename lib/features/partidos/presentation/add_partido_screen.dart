import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/partido_model.dart';
import '../providers/partidos_provider.dart';
import 'share_dialog.dart';

class AddPartidoScreen extends ConsumerStatefulWidget {
  final PartidoModel? editing;
  const AddPartidoScreen({super.key, this.editing});

  @override
  ConsumerState<AddPartidoScreen> createState() => _AddPartidoScreenState();
}

class _AddPartidoScreenState extends ConsumerState<AddPartidoScreen> {
  final _tituloCtrl = TextEditingController();
  final _gfCtrl = TextEditingController();
  final _gcCtrl = TextEditingController();
  late DateTime _dateTime;
  late TipoPartido _tipo;
  late Set<String> _memberIds;
  late List<RosterPlayer> _invitados;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final members = ref.read(groupMembersProvider);
    final memberIdSet = members.map((m) => m.id).toSet();

    if (e != null) {
      _tituloCtrl.text = e.titulo;
      _dateTime = e.dateTime;
      _tipo = e.tipo;
      _gfCtrl.text = e.golesFavor?.toString() ?? '';
      _gcCtrl.text = e.golesContra?.toString() ?? '';
      _memberIds = e.roster
          .where((r) => !r.invitado && memberIdSet.contains(r.id))
          .map((r) => r.id)
          .toSet();
      _invitados = e.roster.where((r) => r.invitado).toList();
    } else {
      _dateTime = DateTime.now();
      _tipo = TipoPartido.f5;
      _memberIds = members.map((m) => m.id).toSet();
      _invitados = [];
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _gfCtrl.dispose();
    _gcCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (!mounted) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day,
          time?.hour ?? _dateTime.hour, time?.minute ?? _dateTime.minute);
    });
  }

  Future<void> _addInvitado() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar invitado'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre del invitado',
            hintText: 'El primo de Fran...',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Agregar')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        _invitados.add(RosterPlayer(
          id: 'g${DateTime.now().microsecondsSinceEpoch}',
          nombre: name,
          invitado: true,
        ));
      });
    }
  }

  Future<void> _save() async {
    final members = ref.read(groupMembersProvider);
    final titulo = _tituloCtrl.text.trim();

    final roster = <RosterPlayer>[
      ...members
          .where((m) => _memberIds.contains(m.id))
          .map((m) => RosterPlayer(id: m.id, nombre: m.nickname)),
      ..._invitados,
    ];

    if (roster.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Agregá al menos 2 jugadores al plantel')));
      return;
    }

    final gf = int.tryParse(_gfCtrl.text.trim());
    final gc = int.tryParse(_gcCtrl.text.trim());
    final currentUser = ref.read(currentUserProvider);

    final partido = PartidoModel(
      id: widget.editing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo.isEmpty ? 'Partido' : titulo,
      dateTime: _dateTime,
      tipo: _tipo,
      golesFavor: gf,
      golesContra: gc,
      roster: roster,
      cerrado: widget.editing?.cerrado ?? false,
      creatorId: widget.editing?.creatorId ?? currentUser?.id ?? '',
    );

    final notifier = ref.read(partidosProvider.notifier);
    if (widget.editing != null) {
      await notifier.update(partido);
      if (mounted) Navigator.of(context).pop();
    } else {
      await notifier.add(partido);
      if (!mounted) return;
      // Al crear un partido nuevo, ofrecemos el link para compartir.
      await showSharePartidoDialog(context, partido);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider);
    final allSelected = _memberIds.length == members.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing != null ? 'Editar partido' : 'Nuevo partido'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 38),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Rival / nombre del partido',
                hintText: 'vs Los del bar',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: widget.editing == null,
            ),
            const SizedBox(height: 16),

            // Fecha y hora
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(fmtDateLong(_dateTime),
                            style: theme.textTheme.bodyMedium)),
                    Icon(Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tipo
            Text('Tipo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final t in TipoPartido.values) ...[
                  _Chip(
                    label: t.label,
                    selected: _tipo == t,
                    onTap: () => setState(() => _tipo = t),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Resultado (opcional)
            Text('Resultado (opcional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gfCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: 'Nosotros'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('-', style: TextStyle(fontSize: 22)),
                ),
                Expanded(
                  child: TextField(
                    controller: _gcCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: 'Ellos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Plantel a encuestar (LST)
            Row(
              children: [
                Text('Plantel a encuestar', style: theme.textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _memberIds = allSelected
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
              children: [
                for (final m in members)
                  FilterChip(
                    avatar: Text(m.avatarEmoji,
                        style: const TextStyle(fontSize: 16)),
                    label: Text(m.nickname),
                    selected: _memberIds.contains(m.id),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _memberIds.add(m.id);
                      } else {
                        _memberIds.remove(m.id);
                      }
                    }),
                    selectedColor:
                        AppColors.partidosColor.withValues(alpha: 0.22),
                    checkmarkColor: AppColors.partidosColor,
                  ),
                // Invitados
                for (final g in _invitados)
                  InputChip(
                    avatar: const Text('⚽', style: TextStyle(fontSize: 16)),
                    label: Text(g.nombre),
                    onDeleted: () =>
                        setState(() => _invitados.remove(g)),
                    backgroundColor:
                        AppColors.partidosColor.withValues(alpha: 0.12),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Invitado'),
                  onPressed: _addInvitado,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.partidosColor.withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.partidosColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            )),
      ),
    );
  }
}
