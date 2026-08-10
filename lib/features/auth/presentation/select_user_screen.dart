import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/avatar_widget.dart';
import '../../../shared/providers/user_provider.dart';

/// Selector "¿Quién sos?" — reemplaza al login con contraseña.
/// Elegís tu nombre y entrás; la elección queda guardada en el dispositivo.
class SelectUserScreen extends ConsumerWidget {
  const SelectUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          children: [
            const Center(child: Text('🔥', style: TextStyle(fontSize: 56))),
            const SizedBox(height: 10),
            Text('La Banda',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium),
            Text('¿Quién sos?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
              children: [
                for (final m in members)
                  _UserTile(
                    onTap: () {
                      ref.read(currentUserProvider.notifier).select(m.id);
                      context.go('/');
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AvatarWidget(user: m, size: 56),
                        const SizedBox(height: 8),
                        Text(m.nickname,
                            style: theme.textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _UserTile({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
    );
  }
}
