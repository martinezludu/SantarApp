import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/user_provider.dart';
import 'widgets/avatar_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _email;
  Uint8List? _bytes;
  String _emoji = '🧑';
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _email = TextEditingController(text: user?.email ?? '');
    _bytes = user?.avatarBytes;
    _emoji = user?.avatarEmoji ?? '🧑';
    _nickname = user?.nickname ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(currentUserProvider.notifier).updateProfile(
          email: _email.text,
          avatarEmoji: _emoji,
          avatarBytes: _bytes,
          removeAvatar: _bytes == null,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado ✅')),
    );
  }

  void _logout() {
    ref.read(currentUserProvider.notifier).logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Mi perfil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Center(
              child: AvatarPicker(
                bytes: _bytes,
                emoji: _emoji,
                onImagePicked: (b) => setState(() => _bytes = b),
                onRemove: () => setState(() => _bytes = null),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(_nickname, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 24),

            Text('O elegí un emoji', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in AppConstants.emojiChoices)
                  GestureDetector(
                    onTap: () => setState(() {
                      _emoji = e;
                      _bytes = null;
                    }),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_emoji == e && _bytes == null)
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Apodo fijo (es el usuario de login)
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Apodo (no editable)',
                hintText: _nickname,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 28),

            FilledButton(onPressed: _save, child: const Text('Guardar cambios')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
