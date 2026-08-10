import 'package:flutter/material.dart';

import '../../../../shared/models/user_model.dart';
import '../../providers/cartas_provider.dart';

/// Carta estilo FIFA Ultimate Team.
class FutCard extends StatelessWidget {
  final Carta carta;
  final UserModel? user; // miembro del grupo, para mostrar su foto/avatar
  final double width;
  final VoidCallback? onTap;

  const FutCard({
    super.key,
    required this.carta,
    this.user,
    this.width = 190,
    this.onTap,
  });

  _TierStyle get _style => switch (carta.tier) {
        CartaTier.icon => const _TierStyle(
            [Color(0xFFF7E7B3), Color(0xFFE9C766)], Color(0xFF5A3E00)),
        CartaTier.gold => const _TierStyle(
            [Color(0xFFF6D365), Color(0xFFC9971E)], Color(0xFF3D2B00)),
        CartaTier.silver => const _TierStyle(
            [Color(0xFFE2E6EC), Color(0xFFAAB2BD)], Color(0xFF2C3038)),
        CartaTier.bronze => const _TierStyle(
            [Color(0xFFE0A47C), Color(0xFFA8683F)], Color(0xFF3A2110)),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final ink = s.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: s.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cabecera: OVR + posición + avatar ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      carta.tieneDatos ? '${carta.ovr}' : '--',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    Text(carta.posicion,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ink)),
                    if (carta.motmCount > 0) ...[
                      const SizedBox(height: 4),
                      Text('⭐${carta.motmCount}',
                          style: TextStyle(fontSize: 12, color: ink)),
                    ],
                  ],
                ),
                const Spacer(),
                _Avatar(user: user, emoji: carta.avatarEmoji, ink: ink),
              ],
            ),
            const SizedBox(height: 8),
            // ── Nombre ──
            Text(
              carta.nombre.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: ink),
            ),
            if (carta.invitado)
              Text('invitado',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ink.withValues(alpha: 0.7))),
            Divider(color: ink.withValues(alpha: 0.3), height: 18),
            // ── Stats en 2 columnas ──
            if (carta.tieneDatos)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _StatRow('PAC', carta.stats100['pac']!, ink),
                        _StatRow('SHO', carta.stats100['sho']!, ink),
                        _StatRow('PAS', carta.stats100['pas']!, ink),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        _StatRow('DRI', carta.stats100['dri']!, ink),
                        _StatRow('DEF', carta.stats100['def']!, ink),
                        _StatRow('PHY', carta.stats100['phy']!, ink),
                      ],
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Sin calificaciones',
                    style: TextStyle(
                        fontSize: 12,
                        color: ink.withValues(alpha: 0.75))),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String abbr;
  final int value;
  final Color ink;
  const _StatRow(this.abbr, this.value, this.ink);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(width: 6),
          Text(abbr,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel? user;
  final String emoji;
  final Color ink;
  const _Avatar({required this.user, required this.emoji, required this.ink});

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (user?.avatarBytes != null) {
      inner = Image.memory(user!.avatarBytes!, fit: BoxFit.cover);
    } else if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      inner = Image.network(user!.avatarUrl!, fit: BoxFit.cover);
    } else {
      inner = Center(child: Text(emoji, style: const TextStyle(fontSize: 32)));
    }
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.25),
        border: Border.all(color: ink.withValues(alpha: 0.4), width: 2),
      ),
      child: inner,
    );
  }
}

class _TierStyle {
  final List<Color> gradient;
  final Color ink;
  const _TierStyle(this.gradient, this.ink);
}
