import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../features/expenses/providers/expenses_provider.dart';
import '../../../features/juntadas/providers/juntadas_provider.dart';
import '../../../features/prode/providers/pronosticos_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final members = ref.watch(groupMembersProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('La Banda', style: theme.textTheme.titleLarge),
                Text('${members.length} integrantes',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar tema',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(mode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: AvatarWidget(
              user: user,
              size: 38,
              showBorder: true,
              onTap: () => context.go('/profile'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Saludo
          Row(
            children: [
              AvatarWidget(user: user, size: 52),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¡Hola, ${user?.nickname ?? 'crack'}! 👋',
                      style: theme.textTheme.titleLarge),
                  Text('¿Qué hacemos hoy?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text('Módulos', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _ModuleCard(
                emoji: '💸',
                title: 'Gastos',
                subtitle: 'Tricount del grupo',
                color: AppColors.expensesColor,
                badge: _ExpensesBadge(),
                onTap: () => context.go(AppRoutes.expenses),
              ),
              _ModuleCard(
                emoji: '🗓',
                title: 'Juntadas',
                subtitle: 'Asados y eventos',
                color: AppColors.juntadasColor,
                badge: _JuntadasBadge(),
                onTap: () => context.go(AppRoutes.juntadas),
              ),
              _ModuleCard(
                emoji: '📊',
                title: 'Stats',
                subtitle: 'Contador de asados',
                color: AppColors.statsColor,
                badge: _StatsBadge(),
                onTap: () => context.go(AppRoutes.stats),
              ),
              _ModuleCard(
                emoji: '🏆',
                title: 'Prode',
                subtitle: 'Mundial 2026',
                color: AppColors.prodeColor,
                badge: _ProdeBadge(),
                onTap: () => context.go(AppRoutes.prode),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Badges dinámicos
// ─────────────────────────────────────────────────────────────────

class _ExpensesBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(expensesProvider).where((e) => !e.isPayment).length;
    if (count == 0) return const SizedBox.shrink();
    return _BadgeChip(
        label: '$count gastos', color: AppColors.expensesColor);
  }
}

class _JuntadasBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juntadas = ref.watch(juntadasProvider);
    if (juntadas.isEmpty) return const SizedBox.shrink();
    final planned =
        juntadas.where((j) => j.status.name == 'planned').length;
    final label = planned > 0 ? '$planned planificadas' : '${juntadas.length} totales';
    return _BadgeChip(label: label, color: AppColors.juntadasColor);
  }
}

class _ProdeBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final totalPts = leaderboard.fold<int>(0, (s, e) => s + e.puntos);
    if (totalPts == 0) return const SizedBox.shrink();
    return _BadgeChip(label: '${leaderboard.first.user.nickname} lidera', color: AppColors.prodeColor);
  }
}

class _StatsBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(finishedJuntadasProvider).length;
    if (count == 0) return const SizedBox.shrink();
    return _BadgeChip(
        label: '$count realizadas', color: AppColors.statsColor);
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

// ─────────────────────────────────────────────────────────────────
// Module card
// ─────────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool enabled;

  const _ModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.badge,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: theme.colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const Spacer(),
                    if (!enabled)
                      Icon(Icons.lock_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
                const Spacer(),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                badge ??
                    Text(subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
