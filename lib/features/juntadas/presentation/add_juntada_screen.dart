import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/juntada_model.dart';
import '../providers/juntadas_provider.dart';

class AddJuntadaScreen extends ConsumerStatefulWidget {
  final JuntadaModel? editing;
  const AddJuntadaScreen({super.key, this.editing});

  @override
  ConsumerState<AddJuntadaScreen> createState() => _AddJuntadaScreenState();
}

class _AddJuntadaScreenState extends ConsumerState<AddJuntadaScreen> {
  final _titleCtrl = TextEditingController();
  final _restaurantCtrl = TextEditingController();
  late DateTime _dateTime;
  late bool _isRestaurant;
  late String _placeUserId;
  late Set<String> _participantIds;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final members = ref.read(groupMembersProvider);
    final currentUser = ref.read(currentUserProvider);

    if (e != null) {
      _titleCtrl.text = e.title;
      _dateTime = e.dateTime;
      _isRestaurant = e.isRestaurant;
      _placeUserId = e.isRestaurant ? '' : e.placeValue;
      _restaurantCtrl.text = e.isRestaurant ? e.placeValue : '';
      _participantIds = e.participantIds.toSet();
    } else {
      _dateTime = DateTime.now();
      _isRestaurant = true;
      _placeUserId = '';
      _participantIds = members.map((m) => m.id).toSet();
    }
    if (currentUser != null) _participantIds.add(currentUser.id);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _restaurantCtrl.dispose();
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
      _dateTime = DateTime(
        date.year, date.month, date.day,
        time?.hour ?? _dateTime.hour,
        time?.minute ?? _dateTime.minute,
      );
    });
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresá un nombre para la juntada')));
      return;
    }
    if (_participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná al menos un participante')));
      return;
    }

    final placeValue =
        _isRestaurant ? _restaurantCtrl.text.trim() : _placeUserId;
    final currentUser = ref.read(currentUserProvider);

    final juntada = JuntadaModel(
      id: widget.editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: _dateTime,
      status: widget.editing?.status ?? JuntadaStatus.planned,
      participantIds: _participantIds.toList(),
      creatorId: widget.editing?.creatorId ?? currentUser?.id ?? '',
      isRestaurant: _isRestaurant,
      placeValue: placeValue,
      roles: widget.editing?.roles ?? const {},
    );

    final notifier = ref.read(juntadasProvider.notifier);
    if (widget.editing != null) {
      notifier.update(juntada);
    } else {
      notifier.add(juntada);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider);
    final allSelected = _participantIds.length == members.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.editing != null ? 'Editar juntada' : 'Nueva juntada'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 38),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
            // ── Título ──
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la juntada',
                hintText: 'Asado del domingo, Cumple de...',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: widget.editing == null,
            ),
            const SizedBox(height: 16),

            // ── Fecha y hora ──
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(fmtDateLong(_dateTime),
                          style: theme.textTheme.bodyMedium),
                    ),
                    Icon(Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Lugar ──
            Text('Lugar', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                _PlaceTypeChip(
                  label: '🍽 Restaurante',
                  selected: _isRestaurant,
                  onTap: () => setState(() {
                    _isRestaurant = true;
                    _placeUserId = '';
                  }),
                ),
                const SizedBox(width: 8),
                _PlaceTypeChip(
                  label: '🏠 Casa de...',
                  selected: !_isRestaurant,
                  onTap: () => setState(() {
                    _isRestaurant = false;
                    _restaurantCtrl.clear();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isRestaurant)
              TextField(
                controller: _restaurantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del restaurante',
                  hintText: 'El Rancho, La Parrilla...',
                ),
              )
            else ...[
              Text('Anfitrión',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length,
                  separatorBuilder: (_, _s) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final m = members[i];
                    final sel = _placeUserId == m.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _placeUserId = sel ? '' : m.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 68,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.juntadasColor
                                  .withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel
                                ? AppColors.juntadasColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(m.avatarEmoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 3),
                            Text(m.nickname,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: sel
                                      ? AppColors.juntadasColor
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
            ],
            const SizedBox(height: 24),

            // ── Participantes ──
            Row(
              children: [
                Text('Participantes', style: theme.textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _participantIds = allSelected
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
                final sel = _participantIds.contains(m.id);
                return FilterChip(
                  avatar: Text(m.avatarEmoji,
                      style: const TextStyle(fontSize: 16)),
                  label: Text(m.nickname),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _participantIds.add(m.id);
                    } else {
                      _participantIds.remove(m.id);
                    }
                  }),
                  selectedColor:
                      AppColors.juntadasColor.withValues(alpha: 0.18),
                  checkmarkColor: AppColors.juntadasColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PlaceTypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.juntadasColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.juntadasColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected
                  ? AppColors.juntadasColor
                  : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            )),
      ),
    );
  }
}
