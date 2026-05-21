import 'package:equatable/equatable.dart';

enum UserRole { admin, teacher, student, curator }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? phone;
  final String? avatar;
  final UserRole role;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phone,
    this.avatar,
    required this.role,
  });

  String get fullName => '$lastName $firstName${middleName != null ? ' $middleName' : ''}';
  String get shortName => '$lastName ${firstName[0]}.${middleName != null ? ' ${middleName![0]}.' : ''}';

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;
  bool get isCurator => role == UserRole.curator;

  @override
  List<Object?> get props => [id, email, role];
}
