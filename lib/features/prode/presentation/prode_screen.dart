import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/partido_model.dart';
import '../providers/partidos_provider.dart';
import '../providers/pronosticos_provider.dart';
import 'pronostico_input_sheet.dart';

class ProdeScreen extends ConsumerStatefulWidget {
  const ProdeScreen({super.key});

  @override
  ConsumerState<ProdeScreen> createState() => _ProdeScreenState();
}

class _ProdeScreenState extends ConsumerState<ProdeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            const Text('Prode 🏆'),
            Text('Mundial 2026',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Partidos'),
            Tab(text: 'Posiciones'),
            Tab(text: 'Admin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _PartidosTab(),
          _PosicionesTab(),
          _AdminTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 1: Partidos
// ─────────────────────────────────────────────────────────────────

const _faseOrder = [
  'Grupo A','Grupo B','Grupo C','Grupo D','Grupo E','Grupo F',
  'Grupo G','Grupo H','Grupo I','Grupo J','Grupo K','Grupo L',
  'Dieciseisavos','Octavos','Cuartos','Semifinal','Tercer Puesto','Final',
];

class _PartidosTab extends ConsumerWidget {
  const _PartidosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidos = ref.watch(partidosProvider);
    final currentUser = ref.watch(currentUserProvider);

    final Map<String, List<PartidoModel>> grouped = {};
    for (final p in partidos) {
      grouped.putIfAbsent(p.grupo, () => []).add(p);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _faseOrder.length,
      itemBuilder: (context, idx) {
        final fase = _faseOrder[idx];
        final lista = grouped[fase];
        if (lista == null || lista.isEmpty) return const SizedBox.shrink();

        final isGrupo = fase.startsWith('Grupo ');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 12),
              child: Text(fase,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),

            // ── Group standings table ──
            if (isGrupo) ...[
              _GroupStandingsTable(grupo: fase),
              const SizedBox(height: 8),
              Text('Partidos',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
            ],

            ...lista.map((p) => _PartidoCard(
                  partido: p,
                  currentUserId: currentUser?.id ?? '',
                )),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Group standings table
// ─────────────────────────────────────────────────────────────────

class _GroupStandingsTable extends ConsumerWidget {
  final String grupo;
  const _GroupStandingsTable({required this.grupo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(groupStandingsProvider(grupo));
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(child: Text('Equipo',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant))),
                for (final h in ['PJ', 'Pts', 'GD', 'GF'])
                  SizedBox(
                    width: 32,
                    child: Text(h, textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...standings.asMap().entries.map((entry) {
            final rank = entry.key;
            final e = entry.value;
            final advances = rank < 2;
            final color = advances
                ? AppColors.prodeColor
                : theme.colorScheme.onSurface;

            return Container(
              decoration: BoxDecoration(
                color: advances
                    ? AppColors.prodeColor.withValues(alpha: 0.05)
                    : null,
                borderRadius: rank == standings.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('${rank + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: Text(e.team,
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: advances ? FontWeight.w700 : FontWeight.normal,
                            color: color),
                        overflow: TextOverflow.ellipsis),
                  ),
                  for (final val in [
                    e.stat.pj,
                    e.stat.pts,
                    e.stat.gd,
                    e.stat.gf,
                  ])
                    SizedBox(
                      width: 32,
                      child: Text(
                        val >= 0 ? '$val' : '$val',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Partido card
// ─────────────────────────────────────────────────────────────────

class _PartidoCard extends ConsumerWidget {
  final PartidoModel partido;
  final String currentUserId;

  const _PartidoCard({required this.partido, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final miProno = ref.watch(miPronosticoProvider(
        (partidoId: partido.id, usuarioId: currentUserId)));
    final isFinalizado = partido.estaFinalizado;
    final isEnCurso = partido.estado == EstadoPartido.enCurso;

    final statusColor = isFinalizado
        ? const Color(0xFF34D399)
        : isEnCurso
            ? AppColors.ember
            : theme.colorScheme.outlineVariant;

    int? myPts;
    if (isFinalizado && miProno != null) {
      myPts = miProno.puntosObtenidos;
    }

    return GestureDetector(
      onTap: () => showPronosticoSheet(context, partido),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: isEnCurso
              ? Border.all(color: AppColors.ember.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${partido.equipoLocal}  vs  ${partido.equipoVisitante}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(_fmtFecha(partido.fechaHora),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      if (isFinalizado) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${partido.golesLocalReal} — ${partido.golesVisitanteReal}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34D399)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (miProno != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${miProno.golesLocal}—${miProno.golesVisitante}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.prodeColor)),
                  if (myPts != null)
                    Text(
                      myPts == 0 ? '0 pts' : '+$myPts pts',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: myPts == 3
                            ? const Color(0xFF34D399)
                            : myPts == 1
                                ? AppColors.ember
                                : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ] else if (!isFinalizado) ...[
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined,
                  size: 16, color: theme.colorScheme.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtFecha(DateTime d) {
    const m = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${m[d.month - 1]}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 2: Posiciones
// ─────────────────────────────────────────────────────────────────

class _PosicionesTab extends ConsumerWidget {
  const _PosicionesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leaderboard = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Tabla de posiciones',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...leaderboard.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final e = entry.value;
          final isMe = e.user.id == currentUser?.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.prodeColor.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: isMe
                  ? Border.all(color: AppColors.prodeColor.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank°',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                Text(e.user.avatarEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.user.nickname,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${e.puntos} pts',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: rank == 1
                        ? const Color(0xFF34D399)
                        : rank <= 3
                            ? AppColors.prodeColor
                            : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 3: Admin
// ─────────────────────────────────────────────────────────────────

class _AdminTab extends ConsumerStatefulWidget {
  const _AdminTab();

  @override
  ConsumerState<_AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends ConsumerState<_AdminTab> {
  String _filter = 'pendientes'; // 'pendientes' | 'todos'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partidos = ref.watch(partidosProvider);

    final visible = _filter == 'pendientes'
        ? partidos.where((p) => !p.estaFinalizado).toList()
        : partidos;

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'Pendientes',
                selected: _filter == 'pendientes',
                onTap: () => setState(() => _filter = 'pendientes'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Todos',
                selected: _filter == 'todos',
                onTap: () => setState(() => _filter = 'todos'),
              ),
              const Spacer(),
              Text('${visible.length} partidos',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),

        // Info banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.ember.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.ember.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high, color: AppColors.ember, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al finalizar un partido, el bracket se actualiza automáticamente. '
                    'Si hay penales, el empate queda — ingresá el ganador en "Actualizar equipos" del próximo partido.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.ember),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text('No hay partidos pendientes 🎉',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: visible.length,
                  itemBuilder: (_, i) =>
                      _AdminPartidoRow(partido: visible[i]),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.prodeColor.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppColors.prodeColor
                  : Colors.transparent),
        ),
        child: Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
                color: selected
                    ? AppColors.prodeColor
                    : theme.colorScheme.onSurface)),
      ),
    );
  }
}

class _AdminPartidoRow extends ConsumerStatefulWidget {
  final PartidoModel partido;
  const _AdminPartidoRow({required this.partido});

  @override
  ConsumerState<_AdminPartidoRow> createState() => _AdminPartidoRowState();
}

class _AdminPartidoRowState extends ConsumerState<_AdminPartidoRow> {
  final _localCtrl = TextEditingController();
  final _visitanteCtrl = TextEditingController();
  final _teamLocalCtrl = TextEditingController();
  final _teamVisitanteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.partido;
    if (p.golesLocalReal != null) { _localCtrl.text = '${p.golesLocalReal}'; }
    if (p.golesVisitanteReal != null) { _visitanteCtrl.text = '${p.golesVisitanteReal}'; }
    _teamLocalCtrl.text = p.equipoLocal;
    _teamVisitanteCtrl.text = p.equipoVisitante;
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _visitanteCtrl.dispose();
    _teamLocalCtrl.dispose();
    _teamVisitanteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.partido;
    final isFinalizado = p.estaFinalizado;
    final isEnCurso = p.estado == EstadoPartido.enCurso;
    final isKnockout = p.esFase;

    final statusIcon = isFinalizado
        ? Icons.check_circle_outline
        : isEnCurso
            ? Icons.sports_soccer
            : Icons.schedule_outlined;
    final statusColor = isFinalizado
        ? const Color(0xFF34D399)
        : isEnCurso
            ? AppColors.ember
            : theme.colorScheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (_) {},
          leading: Icon(statusIcon, color: statusColor, size: 20),
          title: Text(
            '${p.equipoLocal}  vs  ${p.equipoVisitante}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            isFinalizado
                ? '${p.golesLocalReal} — ${p.golesVisitanteReal}  ✓ Finalizado'
                : '${p.grupo}  ·  ${_fmtFecha(p.fechaHora)}',
            style: theme.textTheme.labelSmall?.copyWith(
                color: isFinalizado
                    ? const Color(0xFF34D399)
                    : theme.colorScheme.onSurfaceVariant),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Estado ──
                  Text('Estado', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _estadoChip(theme, p, EstadoPartido.proximamente, 'Próximamente'),
                      _estadoChip(theme, p, EstadoPartido.enCurso, 'En curso'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Resultado ──
                  Text('Resultado final', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _localCtrl,
                          decoration: InputDecoration(
                            labelText: p.equipoLocal,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('—',
                            style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.outlineVariant)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _visitanteCtrl,
                          decoration: InputDecoration(
                            labelText: p.equipoVisitante,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _finalizar,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                          _saving ? 'Guardando...' : 'Finalizar y calcular puntos'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF34D399),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // ── Equipos (knockout) ──
                  if (isKnockout) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Actualizar nombres de equipos',
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Usalo para corregir nombres o asignar el ganador por penales en el próximo partido.',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _teamLocalCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Equipo local', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _teamVisitanteCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Equipo visitante', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final l = _teamLocalCtrl.text.trim();
                          final v = _teamVisitanteCtrl.text.trim();
                          if (l.isEmpty || v.isEmpty) return;
                          ref
                              .read(partidosProvider.notifier)
                              .updateEquipos(p.id, l, v);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Equipos actualizados')));
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Actualizar equipos'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoChip(ThemeData theme, PartidoModel p, EstadoPartido estado, String label) {
    final selected = p.estado == estado;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          ref.read(partidosProvider.notifier).updateEstado(p.id, estado),
      selectedColor: AppColors.prodeColor.withValues(alpha: 0.2),
      checkmarkColor: AppColors.prodeColor,
    );
  }

  Future<void> _finalizar() async {
    final gl = int.tryParse(_localCtrl.text.trim());
    final gv = int.tryParse(_visitanteCtrl.text.trim());
    if (gl == null || gv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresá los goles antes de finalizar')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(partidosProvider.notifier).cargarResultadoYFinalizar(
            widget.partido.id, gl, gv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Resultado cargado ✅  —  $gl — $gv${gl == gv ? "  (empate: actualizá el próximo partido si hubo penales)" : ""}'),
          duration: const Duration(seconds: 4),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmtFecha(DateTime d) {
    const m = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${m[d.month - 1]}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
}
