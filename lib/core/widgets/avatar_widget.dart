import 'package:flutter/material.dart';

import '../../shared/models/user_model.dart';

/// Muestra el avatar del usuario: imagen subida > url remota > emoji fallback.
class AvatarWidget extends StatelessWidget {
  final UserModel? user;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;

  const AvatarWidget({
    super.key,
    required this.user,
    this.size = 44,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (user?.avatarBytes != null) {
      content = Image.memory(user!.avatarBytes!, fit: BoxFit.cover);
    } else if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      content = Image.network(user!.avatarUrl!, fit: BoxFit.cover);
    } else {
      content = Center(
        child: Text(
          user?.avatarEmoji ?? '🧑',
          style: TextStyle(fontSize: size * 0.5),
        ),
      );
    }

    final avatar = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        border: showBorder
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: content,
    );

    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}
