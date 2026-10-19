import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';

/// Modelo de datos para el perfil de usuario.
/// Maneja la conversión desde Supabase Auth y desde la tabla profiles.
class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String role;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  /// Construye desde la tabla `profiles` de Supabase/PowerSync.
  factory UserProfileModel.fromSupabaseRow(Map<String, dynamic> row) {
    return UserProfileModel(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      role: row['role'] as String? ?? 'technician',
      fullName: row['full_name'] as String?,
      phone: row['phone'] as String?,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  /// Construye desde el objeto User de Supabase Auth (fallback offline).
  factory UserProfileModel.fromAuthUser(User user) {
    final meta = user.userMetadata ?? {};
    return UserProfileModel(
      id: user.id,
      email: user.email ?? '',
      role: meta['role'] as String? ?? 'technician',
      fullName: meta['full_name'] as String?,
      phone: meta['phone'] as String?,
      avatarUrl: meta['avatar_url'] as String?,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      role: UserRole.fromString(role),
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }
}
