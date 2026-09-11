import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/tracker/shift_tracker_bloc.dart';
import 'bloc/attendance/attendance_bloc.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_method_screen.dart';
import 'screens/auth/manual_login_screen.dart';
import 'screens/auth/qr_login_screen.dart';
import 'screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VacChatApp());
}

class VacChatApp extends StatelessWidget {
  const VacChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(),
        ),
        BlocProvider<ShiftTrackerBloc>(
          create: (_) => ShiftTrackerBloc(),
        ),
        BlocProvider<AttendanceBloc>(
          create: (_) => AttendanceBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'SRIVA Employee Management - VA Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthenticatedState) {
              return const MainLayout();
            }

            if (state is AuthScreenState) {
              switch (state.screenType) {
                case AuthScreenType.manualLogin:
                  return const ManualLoginScreen();
                case AuthScreenType.qrLogin:
                  return const QrLoginScreen();
                case AuthScreenType.methodSelection:
                  return const LoginMethodScreen();
              }
            }

            return const LoginMethodScreen();
          },
        ),
      ),
    );
  }
}
