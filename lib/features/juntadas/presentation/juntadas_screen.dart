import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../models/juntada_model.dart';
import '../providers/juntadas_provider.dart';
import 'add_juntada_screen.dart';
import 'juntada_detail_screen.dart';

class JuntadasScreen extends ConsumerWidget {
  const JuntadasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juntadas = ref.watch(juntadasProvider);
    final theme = Theme.of(context);
    final finished = juntadas.where((j) => j.status == JuntadaStatus.finished).length;
    final planned = juntadas.length - finished;

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
            const Text('Juntadas 🗓'),
            if (juntadas.isNotEmpty)
              Text('$planned planificadas · $finished finalizadas',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: juntadas.isEmpty
          ? _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: juntadas.length,
              separatorBuilder: (_, _s) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _JuntadaCard(
                juntada: juntadas[i],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => JuntadaDetailScreen(id: juntadas[i].id),
                )),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddJuntadaScreen())),
        backgroundColor: AppColors.juntadasColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗓', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Sin juntadas todavía', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Tocá el + para planificar la próxima',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Juntada card en la lista
// ─────────────────────────────────────────────────────────────────

class _JuntadaCard extends StatelessWidget {
  final JuntadaModel juntada;
  final VoidCallback onTap;
  const _JuntadaCard({required this.juntada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinished = juntada.status == JuntadaStatus.finished;
    final accentColor =
        isFinished ? const Color(0xFF34D399) : AppColors.juntadasColor;

    String placeLabel = '';
    if (juntada.placeValue.isNotEmpty) {
      placeLabel = juntada.isRestaurant
          ? '🍽 ${juntada.placeValue}'
          : '🏠 Casa de...';
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de estado
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(isFinished ? '✅' : '🗓',
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(juntada.title,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(fmtDateLong(juntada.dateTime),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (placeLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(placeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge estado + participantes
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFinished ? 'Finalizada' : 'Planificada',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${juntada.participantIds.length} personas',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
