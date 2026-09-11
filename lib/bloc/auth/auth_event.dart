import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSwitchToMethodSelection extends AuthEvent {}

class AuthSwitchToManualLogin extends AuthEvent {}

class AuthSwitchToQrLogin extends AuthEvent {}

class AuthManualLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AuthManualLoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class AuthQrLoginRequested extends AuthEvent {
  final String token;

  const AuthQrLoginRequested({required this.token});

  @override
  List<Object?> get props => [token];
}

class AuthLogoutRequested extends AuthEvent {}
