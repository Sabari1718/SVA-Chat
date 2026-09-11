import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthScreenState(screenType: AuthScreenType.methodSelection)) {
    on<AuthSwitchToMethodSelection>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.methodSelection));
    });

    on<AuthSwitchToManualLogin>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.manualLogin));
    });

    on<AuthSwitchToQrLogin>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.qrLogin));
    });

    // Real API Login: POST /api/v1/auth/login
    on<AuthManualLoginRequested>((event, emit) async {
      emit(const AuthScreenState(
        screenType: AuthScreenType.manualLogin,
        isLoading: true,
      ));

      if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
        emit(const AuthScreenState(
          screenType: AuthScreenType.manualLogin,
          errorMessage: 'Please enter both Work Email ID and Password.',
          isLoading: false,
        ));
        return;
      }

      try {
        final user = await _authRepository.loginWithCredentials(
          email: event.email,
          password: event.password,
        );

        emit(AuthenticatedState(user: user));
      } catch (e) {
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        emit(AuthScreenState(
          screenType: AuthScreenType.manualLogin,
          errorMessage: cleanMsg,
          isLoading: false,
        ));
      }
    });

    // Real API QR Status Check: GET /api/v1/auth/qr/status/{qrToken}
    on<AuthQrLoginRequested>((event, emit) async {
      emit(const AuthScreenState(
        screenType: AuthScreenType.qrLogin,
        isLoading: true,
      ));

      if (event.token.trim().isEmpty) {
        emit(const AuthScreenState(
          screenType: AuthScreenType.qrLogin,
          errorMessage: 'Invalid QR Token. Please scan or enter a valid token.',
          isLoading: false,
        ));
        return;
      }

      try {
        final qrData = await _authRepository.checkQrStatus(event.token);
        final status = (qrData['status'] as String? ?? 'UNKNOWN').toUpperCase();

        if (status == 'EXPIRED') {
          emit(const AuthScreenState(
            screenType: AuthScreenType.qrLogin,
            errorMessage: 'QR status: EXPIRED. Please refresh the QR code on the desktop portal.',
            isLoading: false,
          ));
        } else if (status == 'SUCCESS' && qrData.containsKey('user')) {
          final user = UserModel.fromJson(
            qrData['user'] as Map<String, dynamic>,
            token: qrData['token'] as String?,
          );
          emit(AuthenticatedState(user: user));
        } else {
          emit(AuthScreenState(
            screenType: AuthScreenType.qrLogin,
            errorMessage: 'QR Status: $status. Waiting for authorization.',
            isLoading: false,
          ));
        }
      } catch (e) {
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        emit(AuthScreenState(
          screenType: AuthScreenType.qrLogin,
          errorMessage: cleanMsg,
          isLoading: false,
        ));
      }
    });

    on<AuthLogoutRequested>((event, emit) {
      emit(const AuthScreenState(screenType: AuthScreenType.methodSelection));
    });
  }
}
