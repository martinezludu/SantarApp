import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'package:santarapp/shared/providers/shared_preferences_provider.dart';

/// Cuentas FIJAS del grupo. No hay registro abierto.
/// La contraseña de cada uno es su propio nombre (apodo).
const _seed = <({String id, String nick, String emoji})>[
  (id: 'u1', nick: 'Iñaki', emoji: '🧉'),
  (id: 'u2', nick: 'JulianS', emoji: '😎'),
  (id: 'u3', nick: 'JulianR', emoji: '🔥'),
  (id: 'u4', nick: 'Chavo', emoji: '🍖'),
  (id: 'u5', nick: 'Rodri', emoji: '⚽'),
  (id: 'u6', nick: 'Uset', emoji: '🎸'),
  (id: 'u7', nick: 'Fran', emoji: '🏃'),
  (id: 'u8', nick: 'Gonza', emoji: '🌙'),
];

UserModel _baseFromSeed(({String id, String nick, String emoji}) s) =>
    UserModel(id: s.id, nickname: s.nick, email: '', avatarEmoji: s.emoji);

final List<UserModel> _baseUsers = _seed.map(_baseFromSeed).toList();

UserModel? _findByNick(String nick) {
  final n = nick.trim().toLowerCase();
  for (final u in _baseUsers) {
    if (u.nickname.toLowerCase() == n) return u;
  }
  return null;
}

UserModel? _findById(String id) {
  for (final u in _baseUsers) {
    if (u.id == id) return u;
  }
  return null;
}

String _overrideKey(String id) => 'profile_override_$id';

/// Aplica al usuario base las personalizaciones guardadas (foto/emoji/email).
UserModel _applyOverride(UserModel base, SharedPreferences prefs) {
  final raw = prefs.getString(_overrideKey(base.id));
  if (raw == null) return base;
  try {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final b64 = j['avatarBase64'] as String?;
    return base.copyWith(
      email: j['email'] as String? ?? base.email,
      avatarEmoji: j['avatarEmoji'] as String? ?? base.avatarEmoji,
      avatarBytes: b64 == null ? null : base64Decode(b64),
      removeAvatarBytes: b64 == null,
    );
  } catch (_) {
    return base;
  }
}

/// Miembros del grupo (con sus personalizaciones aplicadas).
final groupMembersProvider = Provider<List<UserModel>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final current = ref.watch(currentUserProvider);
  return _baseUsers.map((u) {
    if (current != null && current.id == u.id) return current;
    return _applyOverride(u, prefs);
  }).toList();
});

/// Solo los nombres, para mostrarlos en el login.
final usernamesProvider =
    Provider<List<String>>((ref) => _baseUsers.map((u) => u.nickname).toList());

class CurrentUserNotifier extends Notifier<UserModel?> {
  static const _sessionKey = 'current_user_id';

  @override
  UserModel? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final id = prefs.getString(_sessionKey);
    if (id == null) return null;
    final base = _findById(id);
    if (base == null) return null;
    return _applyOverride(base, prefs);
  }

  /// Intenta iniciar sesión. Devuelve `null` si OK, o un mensaje de error.
  String? login(String username, String password) {
    final base = _findByNick(username);
    if (base == null) return 'Ese usuario no existe';
    // La contraseña es el nombre.
    if (password.trim().toLowerCase() != base.nickname.toLowerCase()) {
      return 'Contraseña incorrecta';
    }
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_sessionKey, base.id);
    state = _applyOverride(base, prefs);
    return null;
  }

  /// Edita el perfil (el apodo NO se puede cambiar: es el login).
  void updateProfile({
    String? email,
    String? avatarEmoji,
    Uint8List? avatarBytes,
    bool removeAvatar = false,
  }) {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(
      email: email?.trim(),
      avatarEmoji: avatarEmoji,
      avatarBytes: removeAvatar ? null : avatarBytes,
      removeAvatarBytes: removeAvatar,
    );
    state = updated;

    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
      _overrideKey(updated.id),
      jsonEncode({
        'email': updated.email,
        'avatarEmoji': updated.avatarEmoji,
        'avatarBase64':
            updated.avatarBytes == null ? null : base64Encode(updated.avatarBytes!),
      }),
    );
  }

  void logout() {
    ref.read(sharedPreferencesProvider).remove(_sessionKey);
    state = null;
  }
}

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, UserModel?>(CurrentUserNotifier.new);

final isLoggedInProvider =
    Provider<bool>((ref) => ref.watch(currentUserProvider) != null);
