import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

import '../../../../app/theme/app_colors.dart';

/// Selector grande de avatar con subida de imagen desde el navegador.
/// Usa `image_picker_web` (solo Flutter Web).
class AvatarPicker extends StatelessWidget {
  final Uint8List? bytes;
  final String emoji;
  final double size;
  final ValueChanged<Uint8List> onImagePicked;
  final VoidCallback? onRemove;

  const AvatarPicker({
    super.key,
    required this.bytes,
    required this.emoji,
    required this.onImagePicked,
    this.onRemove,
    this.size = 120,
  });

  Future<void> _pick(BuildContext context) async {
    try {
      final picked = await ImagePickerWeb.getImageAsBytes();
      if (picked != null) onImagePicked(picked);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la imagen 😕')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () => _pick(context),
              child: Container(
                width: size,
                height: size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: AppColors.ember, width: 3),
                ),
                child: bytes != null
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : Center(
                        child: Text(emoji,
                            style: TextStyle(fontSize: size * 0.45))),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _pick(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.ember,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.scaffoldBackgroundColor, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _pick(context),
          icon: const Icon(Icons.upload_rounded, size: 16),
          label: Text(bytes != null ? 'Cambiar foto' : 'Subir foto'),
        ),
        if (bytes != null && onRemove != null)
          TextButton.icon(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline_rounded,
                size: 16, color: theme.colorScheme.error),
            label: Text('Quitar foto',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
      ],
    );
  }
}
