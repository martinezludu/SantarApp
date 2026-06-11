import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/user_provider.dart';
import '../../juntadas/models/juntada_model.dart';
import '../../juntadas/providers/juntadas_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finished = ref.watch(finishedJuntadasProvider);
    final members = ref.watch(groupMembersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Stats 📊'),
      ),
      body: finished.isEmpty
          ? _EmptyState()
          : _StatsBody(finished: finished, members: members),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Cuerpo principal
// ─────────────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  final List<JuntadaModel> finished;
  final List<UserModel> members;

  const _StatsBody({required this.finished, required this.members});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = finished.length;

    // ── Asistencia ──
    final attendance = <String, int>{};
    for (final j in finished) {
      for (final uid in j.participantIds) {
        attendance[uid] = (attendance[uid] ?? 0) + 1;
      }
    }
    final sortedByAttendance = List<UserModel>.from(members)
      ..sort((a, b) =>
          (attendance[b.id] ?? 0).compareTo(attendance[a.id] ?? 0));

    // ── Roles ──
    // roleStats[role][userId] = count
    final roleStats = <String, Map<String, int>>{};
    for (final role in kJuntadaRoles) {
      roleStats[role] = {};
    }
    for (final j in finished) {
      j.roles.forEach((role, uid) {
        if (uid.isNotEmpty && roleStats.containsKey(role)) {
          roleStats[role]![uid] = (roleStats[role]![uid] ?? 0) + 1;
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Resumen ──
        _SummaryCard(total: total),
        const SizedBox(height: 24),

        // ── Asistencia ──
        Text('Ranking de asistencia 🏆',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text('De ${finished.length} juntadas finalizadas',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        ...sortedByAttendance.asMap().entries.map((entry) {
          final rank = entry.key;
          final m = entry.value;
          final count = attendance[m.id] ?? 0;
          final pct = total == 0 ? 0.0 : count / total;
          return _AttendanceRow(
            rank: rank + 1,
            member: m,
            count: count,
            total: total,
            pct: pct,
          );
        }),
        const SizedBox(height: 28),

        // ── Roles ──
        Text('Estadísticas de roles 🎭',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text('¡Para saber quién nunca lava los platos!',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        ...kJuntadaRoles.map((role) => _RoleCard(
              role: role,
              roleData: roleStats[role] ?? {},
              members: members,
              totalJuntadas: total,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int total;
  const _SummaryCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.ember.withValues(alpha: 0.8),
            AppColors.juntadasColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                total == 1 ? 'juntada realizada' : 'juntadas realizadas',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Fila de asistencia por usuario
// ─────────────────────────────────────────────────────────────────

class _AttendanceRow extends StatelessWidget {
  final int rank;
  final UserModel member;
  final int count;
  final int total;
  final double pct;

  const _AttendanceRow({
    required this.rank,
    required this.member,
    required this.count,
    required this.total,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctLabel = '${(pct * 100).round()}%';
    final barColor = rank == 1
        ? AppColors.ember
        : rank <= 3
            ? AppColors.juntadasColor
            : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 24,
            child: Text(
              rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank°',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Text(member.avatarEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.nickname,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$count/$total',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Text(pctLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700, color: barColor)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Card de estadísticas por rol
// ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String role;
  final Map<String, int> roleData; // userId -> count
  final List<UserModel> members;
  final int totalJuntadas;

  const _RoleCard({
    required this.role,
    required this.roleData,
    required this.members,
    required this.totalJuntadas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = kRoleEmojis[role] ?? '🎭';

    // Ordenar: primero los que más veces hicieron el rol
    final sorted = List<UserModel>.from(members)
      ..sort((a, b) =>
          (roleData[b.id] ?? 0).compareTo(roleData[a.id] ?? 0));

    final maxCount =
        sorted.isEmpty ? 0 : (roleData[sorted.first.id] ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 24)),
          title: Text(role,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            maxCount == 0
                ? 'Nadie lo hizo todavía'
                : 'Récord: ${_topName(sorted, roleData)} (${maxCount}x)',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: sorted.map((m) {
                  final count = roleData[m.id] ?? 0;
                  final barPct =
                      maxCount == 0 ? 0.0 : count / maxCount;
                  final neverDid = count == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(m.avatarEmoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 72,
                          child: Text(m.nickname,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: barPct,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                neverDid
                                    ? theme.colorScheme.outlineVariant
                                    : AppColors.ember,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            neverDid ? '¡Nunca!' : '${count}x',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: neverDid
                                  ? AppColors.danger
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: neverDid
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _topName(List<UserModel> sorted, Map<String, int> data) {
    if (sorted.isEmpty) return '?';
    final top = sorted.first;
    return top.nickname;
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────

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
            const Text('📊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Sin datos todavía', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Las estadísticas aparecen cuando haya\njuntadas finalizadas',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
