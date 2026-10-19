import 'package:equatable/equatable.dart';

/// Rol del usuario en el sistema.
/// La aplicación móvil MVP sirve principalmente al rol Technician.
enum UserRole {
  technician,
  office,
  client,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.technician,
    );
  }

  bool get canCreateVisit =>
      this == UserRole.technician || this == UserRole.admin;

  bool get canEditVisit =>
      this == UserRole.technician || this == UserRole.admin;

  bool get canViewAllVisits =>
      this == UserRole.office || this == UserRole.admin;
}

/// Entidad de dominio: Perfil del usuario autenticado.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  final String id;         // UUID de Supabase Auth
  final String email;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  String get displayName => fullName ?? email;

  String get initials {
    if (fullName == null || fullName!.isEmpty) {
      return email.substring(0, 2).toUpperCase();
    }
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  }

  @override
  List<Object?> get props => [id, email, role];
}
