import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:va_chat/bloc/auth/auth_bloc.dart';
import 'package:va_chat/bloc/tracker/shift_tracker_bloc.dart';
import 'package:va_chat/main.dart';
import 'package:va_chat/screens/modules/payslip_screen.dart';
import 'package:va_chat/screens/widgets/session_logout_dialog.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VacChatApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Employee Management'), findsWidgets);
    expect(find.text('Choose Login Method'), findsOneWidget);
  });

  testWidgets('SessionLogoutDialog renders manual and QR logout modes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc()),
          BlocProvider(create: (_) => ShiftTrackerBloc()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SessionLogoutDialog()),
        ),
      ),
    );
    await tester.pump();

    // Verify Session Logout Header and User Pill
    expect(find.text('Session Logout'), findsOneWidget);
    expect(find.text('Sabarishwaran'), findsOneWidget);
    expect(find.text('Active Session'), findsOneWidget);

    // Default: Manual Logout tab
    expect(find.text('Log Out Now'), findsOneWidget);

    // Switch to QR Logout
    await tester.tap(find.text('QR Logout'));
    await tester.pump();

    expect(find.text('Display Logout QR'), findsOneWidget);
    expect(find.text('Generate New Logout QR Code'), findsOneWidget);
    expect(find.textContaining('Expires in:'), findsOneWidget);
  });

  testWidgets('PayslipScreen renders option tabs and opens Company & Signature dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PayslipScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Payslip Management'), findsWidgets);
    expect(find.text('Option 1 - Single Page'), findsOneWidget);

    // Tap Company & Signature button to open modal dialog
    await tester.tap(find.text('Company & Signature'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Company Details & Digital Signature'), findsOneWidget);
    expect(find.text('Authorized Digital Signature Settings'), findsOneWidget);
    expect(find.text('Save Company & Signature Details'), findsOneWidget);

    // Tap cancel to close dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Company Details & Digital Signature'), findsNothing);
  });
}
