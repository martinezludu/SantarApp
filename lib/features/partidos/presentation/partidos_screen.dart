import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/partido_model.dart';
import '../providers/calificaciones_provider.dart';
import '../providers/cartas_provider.dart';
import '../providers/partidos_provider.dart';
import 'add_partido_screen.dart';
import 'calificar_screen.dart';
import 'share_dialog.dart';
import 'widgets/fut_card.dart';

class PartidosScreen extends ConsumerWidget {
  const PartidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/'),
          ),
          title: const Text('⚽ Partidos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Partidos'),
              Tab(text: 'Cartas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_PartidosTab(), _CartasTab()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.partidosColor,
          foregroundColor: Colors.black,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPartidoScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Partido'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab: Partidos
// ─────────────────────────────────────────────────────────────────

class _PartidosTab extends ConsumerWidget {
  const _PartidosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidos = ref.watch(partidosProvider);

    if (partidos.isEmpty) {
      return const _EmptyState(
        emoji: '⚽',
        title: 'Todavía no hay partidos',
        subtitle: 'Cargá el primero con el botón de abajo.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: partidos.length,
      separatorBuilder: (_, _s) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PartidoCard(partido: partidos[i]),
    );
  }
}

class _PartidoCard extends ConsumerWidget {
  final PartidoModel partido;
  const _PartidoCard({required this.partido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final votaron = ref.watch(votantesDePartidoProvider(partido.id));
    final total = partido.roster.length;
    final progreso = votaron.length;

    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(partido.titulo,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                _Pill(
                    text: partido.tipo.short,
                    color: AppColors.partidosColor),
                if (partido.cerrado) ...[
                  const SizedBox(width: 6),
                  _Pill(text: 'Cerrado', color: theme.colorScheme.outline),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(fmtDateLong(partido.dateTime),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (partido.tieneResultado)
                  Text(partido.resultadoLabel,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('$progreso/$total calificaron',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: progreso >= total
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : progreso / total,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: AppColors.partidosColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!partido.cerrado)
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CalificarScreen(partidoId: partido.id),
                        ),
                      ),
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: const Text('Calificar'),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Compartir link',
                  onPressed: () => showSharePartidoDialog(context, partido),
                  icon: const Icon(Icons.ios_share),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más',
                  onSelected: (v) {
                    if (v == 'edit') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              AddPartidoScreen(editing: partido)));
                    } else if (v == 'toggle') {
                      ref
                          .read(partidosProvider.notifier)
                          .toggleCerrado(partido.id);
                    } else if (v == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                        value: 'toggle',
                        child: Text(partido.cerrado
                            ? 'Reabrir partido'
                            : 'Cerrar partido')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar partido?'),
        content: const Text(
            'Se borran el partido y todas sus calificaciones. No se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              ref.read(partidosProvider.notifier).remove(partido.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab: Cartas
// ─────────────────────────────────────────────────────────────────

class _CartasTab extends ConsumerWidget {
  const _CartasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartas = ref.watch(cartasProvider);
    final conDatos = cartas.where((c) => c.tieneDatos).toList();
    final sinDatos = cartas.where((c) => !c.tieneDatos).toList();

    if (conDatos.isEmpty) {
      return const _EmptyState(
        emoji: '🎴',
        title: 'Todavía no hay cartas',
        subtitle: 'Cargá un partido y que el equipo se califique.',
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.62,
      children: [
        for (final c in [...conDatos, ...sinDatos])
          _CartaGridItem(carta: c),
      ],
    );
  }
}

class _CartaGridItem extends ConsumerWidget {
  final Carta carta;
  const _CartaGridItem({required this.carta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref
        .watch(groupMembersProvider)
        .where((m) => m.id == carta.id)
        .firstOrNull;
    return FutCard(
      carta: carta,
      user: user,
      width: double.infinity,
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _CartaDetailSheet(carta: carta, user: user),
      ),
    );
  }
}

class _CartaDetailSheet extends StatelessWidget {
  final Carta carta;
  final UserModel? user;
  const _CartaDetailSheet({required this.carta, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutCard(carta: carta, user: user, width: 230),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniStat(
                    label: 'Partidos',
                    value: '${carta.partidosCalificados}'),
                _MiniStat(label: 'OVR', value: '${carta.ovr}'),
                _MiniStat(label: 'MOTM', value: '⭐ ${carta.motmCount}'),
              ],
            ),
            const SizedBox(height: 20),
            if (carta.tieneDatos)
              for (final s in kStats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 44,
                          child: Text(s.abbr,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (carta.stats100[s.key] ?? 0) / 100,
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: AppColors.partidosColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                          width: 32,
                          child: Text('${carta.stats100[s.key]}',
                              textAlign: TextAlign.end,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800))),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Compartidos
// ─────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
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
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
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
