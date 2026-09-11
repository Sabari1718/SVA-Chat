import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key});

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> with SingleTickerProviderStateMixin {
  final _tokenController = TextEditingController(text: 'QR-TOKEN-SRIVA-EMP-9824');
  int _selectedTab = 1; // 0: Display Login QR, 1: Camera Scanner
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _onAuthenticate() {
    context.read<AuthBloc>().add(
          AuthQrLoginRequested(token: _tokenController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Background ambient glowing orbs
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => context.read<AuthBloc>().add(AuthSwitchToMethodSelection()),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Methods',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 6),
                                Text(
                                  'High-Speed QR Auth',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF38BDF8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Main Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 36,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthScreenState && state.isLoading;
                            final errorMessage = state is AuthScreenState ? state.errorMessage : null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart QR Authentication',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scan your employee badge or mobile pass to instantly start shift.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Sub Tab Switcher
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildSubTab(
                                          index: 1,
                                          title: 'Camera Scanner',
                                          icon: Icons.camera_alt_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: _buildSubTab(
                                          index: 0,
                                          title: 'Display QR Code',
                                          icon: Icons.qr_code_2_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                if (errorMessage != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            errorMessage,
                                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFCA5A5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // SCANNER VIEW
                                if (_selectedTab == 1) ...[
                                  // Animated Cyber Viewfinder
                                  Center(
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.5), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Corner accent markers
                                          ..._buildCornerAccents(),

                                          // Center QR Icon
                                          Icon(
                                            Icons.qr_code_scanner_rounded,
                                            size: 64,
                                            color: Colors.white.withValues(alpha: 0.2),
                                          ),

                                          // Animated Laser Scanner Line
                                          AnimatedBuilder(
                                            animation: _animController,
                                            builder: (context, child) {
                                              return Positioned(
                                                top: 20 + (_animController.value * 170),
                                                left: 20,
                                                right: 20,
                                                child: Container(
                                                  height: 2,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Color(0xFF38BDF8),
                                                        Color(0xFF818CF8),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          Positioned(
                                            bottom: 14,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.7),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Align QR within frame',
                                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // DISPLAY QR VIEW
                                  Center(
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      child: CustomPaint(
                                        painter: _AuthQRPainter(),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),

                                // Token Input
                                Text(
                                  'Employee QR Pass Token',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _tokenController,
                                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: 'Enter QR token string...',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFF38BDF8)),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Authenticate Action Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _onAuthenticate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Verify QR & Enter Portal',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerAccents() {
    const size = 18.0;
    const thickness = 2.5;
    const color = Color(0xFF38BDF8);

    return [
      Positioned(
        top: 14,
        left: 14,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      Positioned(
        top: 14,
        right: 14,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 14,
        left: 14,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 14,
        right: 14,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
    ];
  }
}

class _AuthQRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blackPaint = Paint()..color = const Color(0xFF0F172A);
    const int matrixSize = 21;
    final double cellSize = size.width / matrixSize;

    final pattern = [
      [1,1,1,1,1,1,1, 0, 1,0,1,0,1, 0, 1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1, 0, 0,1,1,0,1, 0, 1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1, 0, 1,0,0,1,0, 0, 1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1, 0, 0,1,1,0,1, 0, 1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1, 0, 1,1,0,1,0, 0, 1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1, 0, 0,1,0,1,1, 0, 1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1, 0, 1,0,1,0,1, 0, 1,1,1,1,1,1,1],
      [0,0,0,0,0,0,0, 0, 1,1,0,0,1, 0, 0,0,0,0,0,0,0],
      [1,0,1,0,1,1,1, 1, 0,1,0,1,0, 1, 1,0,1,0,1,1,0],
      [0,1,0,1,0,0,0, 1, 1,0,1,1,0, 0, 0,1,1,0,0,1,1],
      [1,1,0,1,1,0,1, 0, 0,1,1,0,1, 1, 1,0,0,1,0,1,0],
      [0,0,1,0,0,1,0, 1, 1,0,0,1,0, 0, 0,1,1,0,1,0,1],
      [1,0,1,1,0,1,1, 0, 1,1,0,1,1, 1, 1,0,0,1,0,1,0],
      [0,0,0,0,0,0,0, 0, 0,1,1,0,0, 1, 0,1,0,1,1,0,1],
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
              const Radius.circular(1.5),
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
