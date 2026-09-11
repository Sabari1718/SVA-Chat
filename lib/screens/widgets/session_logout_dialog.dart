import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/tracker/shift_tracker_bloc.dart';
import '../../bloc/tracker/shift_tracker_event.dart';
import '../../core/theme/app_colors.dart';

class SessionLogoutDialog extends StatefulWidget {
  const SessionLogoutDialog({super.key});

  @override
  State<SessionLogoutDialog> createState() => _SessionLogoutDialogState();
}

class _SessionLogoutDialogState extends State<SessionLogoutDialog> {
  int _selectedMethod = 0; // 0: Manual Logout, 1: QR Logout
  int _qrSubTab = 0; // 0: Display Logout QR, 1: Scan Logout QR Code
  int _countdown = 57;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (_countdown > 1) {
            _countdown--;
          } else {
            _countdown = 60; // Auto renew
          }
        });
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _countdown = 60;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New Logout QR generated!'),
        backgroundColor: Color(0xFFDC2626),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _performLogout() {
    Navigator.of(context).pop();
    context.read<ShiftTrackerBloc>().add(PauseShiftEvent());
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header matching Screenshot 3
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Logout',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Select your preferred session logout method',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Info Pill matching Screenshot 3 & 4
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFEF4444),
                            child: Text(
                              'SA',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sabarishwaran',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'emp-101',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'EMPLOYEE',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Active Session',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Method Tabs (Manual Logout vs QR Logout)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              index: 0,
                              icon: Icons.logout_rounded,
                              label: 'Manual Logout',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildTabButton(
                              index: 1,
                              icon: Icons.qr_code_rounded,
                              label: 'QR Logout',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // TAB CONTENT
                    if (_selectedMethod == 0) ...[
                      // MANUAL LOGOUT TAB (Screenshot 3)
                      Text(
                        'Are you sure you want to log out of your current session? You will need to enter your credentials to log back in.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _performLogout,
                            icon: const Icon(Icons.logout_rounded, size: 15, color: Colors.white),
                            label: Text(
                              'Log Out Now',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // QR LOGOUT TAB (Screenshot 4)
                      // Dedicated Logout QR red banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dedicated Logout QR: Scanning this QR code terminates your active session within 1 second.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFDC2626),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sub-toggle row matching Screenshot 4:
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _qrSubTab = 0),
                              icon: Icon(
                                Icons.qr_code_rounded,
                                size: 14,
                                color: _qrSubTab == 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                              ),
                              label: Text(
                                'Display Logout QR',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: _qrSubTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                  color: _qrSubTab == 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _qrSubTab == 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                                ),
                                backgroundColor: _qrSubTab == 0 ? const Color(0xFFFEF2F2) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _qrSubTab = 1),
                              icon: Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 14,
                                color: _qrSubTab == 1 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                              ),
                              label: Text(
                                'Scan Logout QR Code',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: _qrSubTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                  color: _qrSubTab == 1 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _qrSubTab == 1 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                                ),
                                backgroundColor: _qrSubTab == 1 ? const Color(0xFFFEF2F2) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_qrSubTab == 0) ...[
                        // Display Logout QR (Screenshot 4)
                        Center(
                          child: Column(
                            children: [
                              // Styled QR Box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildRealisticQRCode(),
                              ),
                              const SizedBox(height: 10),

                              // Countdown Pill badge matching Screenshot 4: "Expires in: 57s"
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Expires in: ${_countdown}s',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Text(
                                'Scan this dedicated Logout QR code with another authorized device to terminate your session instantly.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),

                              OutlinedButton.icon(
                                onPressed: _resetTimer,
                                icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFDC2626)),
                                label: Text(
                                  'Generate New Logout QR Code',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFECACA)),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Quick single-device terminate button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _performLogout,
                                  icon: const Icon(Icons.logout_rounded, size: 15, color: Colors.white),
                                  label: Text(
                                    'Terminate Session Immediately',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Scan Logout QR View
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFEF4444), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 28),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Align Logout QR code to scan',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _performLogout,
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 15, color: Colors.white),
                            label: Text(
                              'Simulate Camera Scan & Log Out',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == index;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFFDC2626) : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFFDC2626) : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealisticQRCode() {
    // Custom crisp QR visual layout matching Screenshot 4
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _QRPainter(),
      ),
    );
  }
}

class _QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blackPaint = Paint()..color = const Color(0xFF0F172A);
    const int matrixSize = 21;
    final double cellSize = size.width / matrixSize;

    // Fixed pattern generator simulating standard QR code
    final pattern = [
      // row 0-6 top finder patterns
      [1,1,1,1,1,1,1, 0, 1,0,1,0,1, 0, 1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1, 0, 0,1,1,0,1, 0, 1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1, 0, 1,0,0,1,0, 0, 1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1, 0, 0,1,1,0,1, 0, 1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1, 0, 1,1,0,1,0, 0, 1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1, 0, 0,1,0,1,1, 0, 1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1, 0, 1,0,1,0,1, 0, 1,1,1,1,1,1,1],
      // row 7
      [0,0,0,0,0,0,0, 0, 1,1,0,0,1, 0, 0,0,0,0,0,0,0],
      // row 8-12 middle data
      [1,0,1,0,1,1,1, 1, 0,1,0,1,0, 1, 1,0,1,0,1,1,0],
      [0,1,0,1,0,0,0, 1, 1,0,1,1,0, 0, 0,1,1,0,0,1,1],
      [1,1,0,1,1,0,1, 0, 0,1,1,0,1, 1, 1,0,0,1,0,1,0],
      [0,0,1,0,0,1,0, 1, 1,0,0,1,0, 0, 0,1,1,0,1,0,1],
      [1,0,1,1,0,1,1, 0, 1,1,0,1,1, 1, 1,0,0,1,0,1,0],
      // row 13
      [0,0,0,0,0,0,0, 0, 0,1,1,0,0, 1, 0,1,0,1,1,0,1],
      // row 14-20 bottom-left finder pattern & data
      [1,1,1,1,1,1,1, 0, 1,0,1,1,0, 0, 1,1,0,0,1,0,1],
      [1,0,0,0,0,0,1, 0, 0,1,0,0,1, 1, 0,0,1,1,0,1,0],
      [1,0,1,1,1,0,1, 0, 1,1,1,0,1, 0, 1,0,1,0,1,0,1],
      [1,0,1,1,1,0,1, 0, 0,0,1,1,0, 1, 0,1,0,1,0,1,0],
      [1,0,1,1,1,0,1, 0, 1,0,0,1,1, 0, 1,1,0,0,1,1,1],
      [1,0,0,0,0,0,1, 0, 0,1,1,0,0, 1, 0,0,1,1,0,1,0],
      [1,1,1,1,1,1,1, 0, 1,0,1,1,0, 1, 1,0,1,0,1,0,1],
    ];

    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        if (pattern[r][c] == 1) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
              const Radius.circular(1),
            ),
            blackPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
