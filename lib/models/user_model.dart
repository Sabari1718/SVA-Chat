import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatarInitials;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarInitials,
  });

  static const defaultUser = UserModel(
    id: 'EMP-9824',
    name: 'Sabarishwaran',
    email: 'sabarishwaran@srivagroups.in',
    role: 'Employee',
    avatarInitials: 'S',
  );

  @override
  List<Object?> get props => [id, name, email, role, avatarInitials];
}
