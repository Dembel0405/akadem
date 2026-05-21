import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.middleName,
    super.phone,
    super.avatar,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      middleName: json['middleName'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      role: _parseRole(json['role'] as String),
    );
  }

  static UserRole _parseRole(String role) => switch (role) {
        'ADMIN' => UserRole.admin,
        'TEACHER' => UserRole.teacher,
        'STUDENT' => UserRole.student,
        'CURATOR' => UserRole.curator,
        _ => UserRole.student,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'phone': phone,
        'avatar': avatar,
        'role': role.name.toUpperCase(),
      };
}
