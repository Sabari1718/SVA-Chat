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
    final userEmail = (json['email'] as String? ?? '').trim();
    final rawRole = (json['role'] as String?)?.trim();
    final bool isExplicitAdmin = json['isAdmin'] == true;
    final determinedRole = rawRole ??
        (isExplicitAdmin || userEmail.toLowerCase() == 'kalaivanissd@gmail.com'
            ? 'admin'
            : 'employee');

    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['employeeId']?.toString() ?? json['empId']?.toString() ?? json['phone']?.toString() ?? '',
      name: name,
      email: userEmail,
      role: determinedRole,
      status: json['status'] as String?,
      avatar: json['avatar'] as String?,
      department: json['department'] as String?,
      businessId: json['businessId'] as String?,
      token: token,
      loginAt: loginAt,
      avatarInitials: initials,
    );
  }

  bool get isAdmin {
    final cleanRole = role.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();
    return cleanRole == 'admin' ||
        cleanRole == 'administrator' ||
        cleanRole.contains('admin') ||
        cleanEmail == 'kalaivanissd@gmail.com';
  }

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
