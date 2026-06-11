import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/partido_model.dart';
import '../models/pronostico_model.dart';
import '../providers/pronosticos_provider.dart';

void showPronosticoSheet(BuildContext context, PartidoModel partido) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PronosticoSheet(partido: partido),
  );
}

class _PronosticoSheet extends ConsumerStatefulWidget {
  final PartidoModel partido;
  const _PronosticoSheet({required this.partido});

  @override
  ConsumerState<_PronosticoSheet> createState() => _PronosticoSheetState();
}

class _PronosticoSheetState extends ConsumerState<_PronosticoSheet> {
  int _golesLocal = 0;
  int _golesVisitante = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      final existing = ref.read(miPronosticoProvider(
          (partidoId: widget.partido.id, usuarioId: currentUser.id)));
      if (existing != null) {
        setState(() {
          _golesLocal = existing.golesLocal;
          _golesVisitante = existing.golesVisitante;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partido = widget.partido;
    final currentUser = ref.watch(currentUserProvider);
    final isFinalizado = partido.estaFinalizado;

    // Privacy: only show others' predictions if partido is finalizado
    final pronosticosDePartido = isFinalizado
        ? ref.watch(pronosticosDePartidoProvider(partido.id))
        : ref
            .watch(pronosticosDePartidoProvider(partido.id))
            .where((p) => p.usuarioId == currentUser?.id)
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),

          // Título del partido
          Text(
            '${partido.equipoLocal}  vs  ${partido.equipoVisitante}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            partido.grupo,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          if (isFinalizado) ...[
            // Show result
            _ResultadoFinal(partido: partido),
            const SizedBox(height: 16),
          ] else if (!isFinalizado && currentUser != null) ...[
            // Score input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreStepper(
                  label: partido.equipoLocal,
                  value: _golesLocal,
                  onChanged: (v) => setState(() => _golesLocal = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('—',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: theme.colorScheme.outlineVariant)),
                ),
                _ScoreStepper(
                  label: partido.equipoVisitante,
                  value: _golesVisitante,
                  onChanged: (v) => setState(() => _golesVisitante = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                ref.read(pronosticosProvider.notifier).guardarPronostico(
                      partidoId: partido.id,
                      usuarioId: currentUser.id,
                      golesLocal: _golesLocal,
                      golesVisitante: _golesVisitante,
                    );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pronóstico guardado ✅')));
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prodeColor,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Guardar pronóstico'),
            ),
            const SizedBox(height: 16),
          ],

          // Pronósticos de otros (solo visibles si finalizado)
          if (pronosticosDePartido.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isFinalizado ? 'Pronósticos del grupo' : 'Mi pronóstico',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            ...pronosticosDePartido.map((p) => _PronosticoRow(
                  prono: p,
                  partido: partido,
                )),
          ] else if (!isFinalizado) ...[
            Text(
              'Los pronósticos de los demás se revelan cuando el partido termina',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _ScoreStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.prodeColor.withValues(alpha: 0.15),
                foregroundColor: AppColors.prodeColor,
                minimumSize: const Size(36, 36),
              ),
            ),
            const SizedBox(width: 12),
            Text('$value',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.prodeColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultadoFinal extends StatelessWidget {
  final PartidoModel partido;
  const _ResultadoFinal({required this.partido});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Resultado final',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Text(
            '${partido.golesLocalReal} — ${partido.golesVisitanteReal}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF34D399),
            ),
          ),
        ],
      ),
    );
  }
}

class _PronosticoRow extends ConsumerWidget {
  final PronosticoModel prono;
  final PartidoModel partido;
  const _PronosticoRow({required this.prono, required this.partido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider);
    final user = members.firstWhere((m) => m.id == prono.usuarioId,
        orElse: () => members.first);
    final pts = prono.puntosObtenidos;
    final Color ptColor = pts == 3
        ? const Color(0xFF34D399)
        : pts == 1
            ? AppColors.ember
            : theme.colorScheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(user.avatarEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(user.nickname,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Text('${prono.golesLocal} — ${prono.golesVisitante}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (partido.estaFinalizado) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ptColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pts == 0 ? '0 pts' : '+$pts pts',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ptColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
