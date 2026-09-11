import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

enum AuthScreenType { methodSelection, manualLogin, qrLogin }

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthScreenState extends AuthState {
  final AuthScreenType screenType;
  final String? errorMessage;
  final bool isLoading;

  const AuthScreenState({
    required this.screenType,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [screenType, errorMessage, isLoading];
}

class AuthenticatedState extends AuthState {
  final UserModel user;

  const AuthenticatedState({required this.user});

  @override
  List<Object?> get props => [user];
}
