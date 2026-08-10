import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../models/calificacion_model.dart';
import '../models/partido_model.dart';
import '../providers/calificaciones_provider.dart';
import '../providers/partidos_provider.dart';

class CalificarScreen extends ConsumerStatefulWidget {
  final String partidoId;
  const CalificarScreen({super.key, required this.partidoId});

  @override
  ConsumerState<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends ConsumerState<CalificarScreen> {
  String? _voterId;
  bool _done = false;
  // targetId -> (statKey -> valor 1..5)
  final Map<String, Map<String, int>> _ratings = {};

  void _pickVoter(String id, List<CalificacionModel> yaHechas) {
    // Precargar votos previos de este votante (para editar).
    _ratings.clear();
    for (final c in yaHechas.where((c) => c.voterId == id)) {
      _ratings[c.targetId] = {for (final s in kStats) s.key: c.stat(s.key)};
    }
    setState(() => _voterId = id);
  }

  int _val(String targetId, String statKey) =>
      _ratings[targetId]?[statKey] ?? 3;

  void _set(String targetId, String statKey, int v) {
    setState(() {
      _ratings.putIfAbsent(
          targetId, () => {for (final s in kStats) s.key: 3});
      _ratings[targetId]![statKey] = v;
    });
  }

  Future<void> _submit(PartidoModel partido) async {
    final voterId = _voterId!;
    final targets = partido.roster.where((r) => r.id != voterId);
    final votos = <CalificacionModel>[];
    for (final t in targets) {
      final r = _ratings[t.id] ?? {for (final s in kStats) s.key: 3};
      votos.add(CalificacionModel(
        id: '${partido.id}_${voterId}_${t.id}',
        partidoId: partido.id,
        voterId: voterId,
        targetId: t.id,
        pac: r['pac']!,
        sho: r['sho']!,
        pas: r['pas']!,
        dri: r['dri']!,
        def: r['def']!,
        phy: r['phy']!,
      ));
    }
    await ref
        .read(calificacionesProvider.notifier)
        .submitVotos(partido.id, voterId, votos);
    if (!mounted) return;
    // En la app (con back stack) volvemos; por deep-link mostramos "gracias".
    if (Navigator.of(context).canPop()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Calificaciones guardadas! 🎉')),
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partidos = ref.watch(partidosProvider);
    final partido = ref.watch(partidoByIdProvider(widget.partidoId));
    final califs =
        ref.watch(calificacionesDePartidoProvider(widget.partidoId));

    if (_done) return _ThankYou();

    if (partido == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: partidos.isEmpty
              ? const CircularProgressIndicator()
              : const Text('Partido no encontrado'),
        ),
      );
    }

    if (partido.cerrado) {
      return Scaffold(
        appBar: AppBar(title: Text(partido.titulo)),
        body: const _Info(
          emoji: '🔒',
          title: 'Este partido está cerrado',
          subtitle: 'Ya no se pueden cargar calificaciones.',
        ),
      );
    }

    final yaVotaron = califs.map((c) => c.voterId).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(_voterId == null ? '¿Quién sos?' : 'Calificá al equipo'),
      ),
      body: _voterId == null
          ? _VoterPicker(
              partido: partido,
              yaVotaron: yaVotaron,
              onPick: (id) => _pickVoter(id, califs),
            )
          : _RatingList(
              partido: partido,
              voterId: _voterId!,
              valueOf: _val,
              onChanged: _set,
            ),
      bottomNavigationBar: _voterId == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => _submit(partido),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.partidosColor,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(yaVotaron.contains(_voterId)
                      ? 'Actualizar mis calificaciones'
                      : 'Guardar calificaciones'),
                ),
              ),
            ),
    );
  }
}

class _VoterPicker extends StatelessWidget {
  final PartidoModel partido;
  final Set<String> yaVotaron;
  final void Function(String id) onPick;
  const _VoterPicker(
      {required this.partido,
      required this.yaVotaron,
      required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Elegí tu nombre para calificar a tus compañeros.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        for (final p in partido.roster)
          Card(
            color: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Text(p.invitado ? '⚽' : '🧑',
                  style: const TextStyle(fontSize: 24)),
              title: Text(p.nombre),
              trailing: yaVotaron.contains(p.id)
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.chevron_right),
              subtitle:
                  yaVotaron.contains(p.id) ? const Text('Ya calificó') : null,
              onTap: () => onPick(p.id),
            ),
          ),
      ],
    );
  }
}

class _RatingList extends StatelessWidget {
  final PartidoModel partido;
  final String voterId;
  final int Function(String targetId, String statKey) valueOf;
  final void Function(String targetId, String statKey, int v) onChanged;
  const _RatingList({
    required this.partido,
    required this.voterId,
    required this.valueOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = partido.roster.where((r) => r.id != voterId).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.partidosColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Tu calificación es anónima.',
                    style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final t in targets) ...[
          Text(t.nombre,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final s in kStats)
                    _StatSelector(
                      stat: s,
                      value: valueOf(t.id, s.key),
                      onChanged: (v) => onChanged(t.id, s.key, v),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _StatSelector extends StatelessWidget {
  final StatDef stat;
  final int value;
  final ValueChanged<int> onChanged;
  const _StatSelector(
      {required this.stat, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Text(stat.emoji),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(stat.abbr,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Spacer(),
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: i <= value
                      ? AppColors.partidosColor
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThankYou extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _Info(
        emoji: '🎉',
        title: '¡Gracias por calificar!',
        subtitle: 'Tus votos ya se guardaron. Podés cerrar esta pestaña.',
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _Info(
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
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
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
