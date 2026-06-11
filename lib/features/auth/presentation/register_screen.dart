import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/user_provider.dart';
import '../../profile/presentation/widgets/avatar_picker.dart';

const kEmojiChoices = [
  '🧑', '😎', '🔥', '🍖', '⚽', '🎸',
  '🌙', '🏃', '🧔', '🤠', '🐺', '👽',
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nick = TextEditingController();
  final _email = TextEditingController();
  Uint8List? _bytes;
  String _emoji = '🧑';

  @override
  void dispose() {
    _nick.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nick.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poné un apodo para arrancar 🔥')),
      );
      return;
    }
    ref.read(currentUserProvider.notifier).register(
          nickname: _nick.text,
          email: _email.text,
          avatarEmoji: _emoji,
          avatarBytes: _bytes,
        );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text('🔥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('Sumate a la banda', style: theme.textTheme.headlineMedium),
            Text('Creá tu perfil del grupo',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),

            // Avatar + subida de imagen
            Center(
              child: AvatarPicker(
                bytes: _bytes,
                emoji: _emoji,
                onImagePicked: (b) => setState(() => _bytes = b),
                onRemove: () => setState(() => _bytes = null),
              ),
            ),
            const SizedBox(height: 20),

            // Selector de emoji (fallback si no hay foto)
            Text('O elegí un emoji',
                style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kEmojiChoices)
                  _EmojiChip(
                    emoji: e,
                    selected: _emoji == e && _bytes == null,
                    onTap: () => setState(() {
                      _emoji = e;
                      _bytes = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nick,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Apodo',
                hintText: 'El Tano, Gordo, Flaco...',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                hintText: 'vos@email.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 28),

            FilledButton(
              onPressed: _submit,
              child: const Text('Crear cuenta'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Ya tengo cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _EmojiChip(
      {required this.emoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
