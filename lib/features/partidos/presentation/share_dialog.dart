import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../models/partido_model.dart';

/// Construye el link compartible que abre la encuesta del partido.
/// Usa hash-strategy (el default de Flutter web): host/.../#/p/<id>.
String buildPartidoLink(String id) {
  final b = Uri.base;
  var path = b.path;
  if (!path.endsWith('/')) {
    // Si la ruta apunta a un archivo (ej: /index.html), quedarse con el dir.
    final i = path.lastIndexOf('/');
    path = i >= 0 ? path.substring(0, i + 1) : '/';
  }
  return '${b.origin}$path#/p/$id';
}

/// Muestra un diálogo con el link para compartir el partido.
Future<void> showSharePartidoDialog(
    BuildContext context, PartidoModel partido) async {
  final link = buildPartidoLink(partido.id);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: const Text('Compartir partido 🔗'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pasales este link a los del plantel. Entran, eligen su nombre y califican al equipo.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                link,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.partidosColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Link copiado ✅')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar link'),
          ),
        ],
      );
    },
  );
}
