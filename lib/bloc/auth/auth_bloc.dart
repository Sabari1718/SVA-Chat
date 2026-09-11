import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthScreenState(screenType: AuthScreenType.methodSelection)) {
    on<AuthSwitchToMethodSelection>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.methodSelection));
    });

    on<AuthSwitchToManualLogin>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.manualLogin));
    });

    on<AuthSwitchToQrLogin>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.qrLogin));
    });

    on<AuthManualLoginRequested>((event, emit) async {
      emit(const AuthScreenState(
        screenType: AuthScreenType.manualLogin,
        isLoading: true,
      ));

      // Simulate network authentication
      await Future.delayed(const Duration(milliseconds: 900));

      if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
        emit(const AuthScreenState(
          screenType: AuthScreenType.manualLogin,
          errorMessage: 'Please enter both Work Email ID and Password.',
          isLoading: false,
        ));
        return;
      }

      // Successful login
      emit(AuthenticatedState(
        user: UserModel(
          id: 'EMP-9824',
          name: event.email.split('@').first.replaceRange(0, 1, event.email[0].toUpperCase()),
          email: event.email,
          role: 'Employee',
          avatarInitials: event.email[0].toUpperCase(),
        ),
      ));
    });

    on<AuthQrLoginRequested>((event, emit) async {
      emit(const AuthScreenState(
        screenType: AuthScreenType.qrLogin,
        isLoading: true,
      ));

      // Simulate QR token validation
      await Future.delayed(const Duration(milliseconds: 900));

      if (event.token.trim().isEmpty) {
        emit(const AuthScreenState(
          screenType: AuthScreenType.qrLogin,
          errorMessage: 'Invalid QR Token. Please scan or enter a valid token.',
          isLoading: false,
        ));
        return;
      }

      emit(const AuthenticatedState(user: UserModel.defaultUser));
    });

    on<AuthLogoutRequested>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.methodSelection));
    });
  }
}
