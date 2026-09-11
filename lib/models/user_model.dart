import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? status;
  final String? avatar;
  final String? department;
  final String? businessId;
  final String? token;
  final String? loginAt;
  final String avatarInitials;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status,
    this.avatar,
    this.department,
    this.businessId,
    this.token,
    this.loginAt,
    required this.avatarInitials,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token, String? loginAt}) {
    final name = json['name'] as String? ?? 'Employee';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'E';

    return UserModel(
      id: json['id'] as String? ?? '',
      name: name,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      status: json['status'] as String?,
      avatar: json['avatar'] as String?,
      department: json['department'] as String?,
      businessId: json['businessId'] as String?,
      token: token,
      loginAt: loginAt,
      avatarInitials: initials,
    );
  }

  bool get isAdmin => role.toLowerCase() == 'admin';

  static const defaultUser = UserModel(
    id: 'emp-11',
    name: 'Sabarishwaran',
    email: 'sabarishwaran1718@gmail.com',
    role: 'employee',
    department: 'App Developer',
    avatarInitials: 'S',
  );

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        status,
        avatar,
        department,
        businessId,
        token,
        loginAt,
        avatarInitials,
      ];
}
