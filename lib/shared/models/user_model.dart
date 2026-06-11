import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Usuario del grupo.
///
/// - [avatarBytes]: imagen subida localmente (Flutter Web). Es lo que se
///   muestra y lo que se persiste (como base64) hasta conectar Firebase.
/// - [avatarUrl]: reservado para la URL remota futura (Firebase Storage).
/// - [avatarEmoji]: fallback cuando no hay imagen.
class UserModel extends Equatable {
  final String id;
  final String nickname;
  final String email;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final String avatarEmoji;

  const UserModel({
    required this.id,
    required this.nickname,
    required this.email,
    this.avatarUrl,
    this.avatarBytes,
    this.avatarEmoji = '🧑',
  });

  bool get hasImage =>
      avatarBytes != null || (avatarUrl != null && avatarUrl!.isNotEmpty);

  UserModel copyWith({
    String? id,
    String? nickname,
    String? email,
    String? avatarUrl,
    Uint8List? avatarBytes,
    String? avatarEmoji,
    bool removeAvatarBytes = false,
    bool removeAvatarUrl = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      avatarUrl: removeAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      avatarBytes:
          removeAvatarBytes ? null : (avatarBytes ?? this.avatarBytes),
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'email': email,
        'avatarUrl': avatarUrl,
        'avatarBase64':
            avatarBytes == null ? null : base64Encode(avatarBytes!),
        'avatarEmoji': avatarEmoji,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final b64 = json['avatarBase64'] as String?;
    return UserModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      avatarBytes: b64 == null ? null : base64Decode(b64),
      avatarEmoji: json['avatarEmoji'] as String? ?? '🧑',
    );
  }

  @override
  List<Object?> get props =>
      [id, nickname, email, avatarUrl, avatarBytes, avatarEmoji];
}
