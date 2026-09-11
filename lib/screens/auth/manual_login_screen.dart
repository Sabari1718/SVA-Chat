import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';

class ManualLoginScreen extends StatefulWidget {
  const ManualLoginScreen({super.key});

  @override
  State<ManualLoginScreen> createState() => _ManualLoginScreenState();
}

class _ManualLoginScreenState extends State<ManualLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    context.read<AuthBloc>().add(
          AuthManualLoginRequested(
            email: _emailController.text,
            password: _passwordController.text,
            rememberMe: _rememberMe,
          ),
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
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4F46E5).withValues(alpha: 0.3),
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
                      // Top navigation bar with Back button
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
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF818CF8)),
                                const SizedBox(width: 6),
                                Text(
                                  '256-Bit SSL Secured',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF818CF8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Main Card
                      Container(
                        padding: const EdgeInsets.all(26),
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
                                // Title Header
                                Text(
                                  'Welcome Back',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enter your corporate credentials to resume your workspace.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 22),

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

                                // Email Input
                                _buildInputLabel('Email Address'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                    prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF818CF8)),
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
                                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Password Input
                                _buildInputLabel('Password'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF818CF8)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 18,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
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
                                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Remember Me checkbox
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: const Color(0xFF4F46E5),
                                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Keep session active',
                                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Forgot?',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF818CF8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // High Impact Gradient Sign In CTA
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.accentGradient,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _onLoginPressed,
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
                                                Text(
                                                  'Sign In to Workspace',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Quick switch to QR Login
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () => context.read<AuthBloc>().add(AuthSwitchToQrLogin()),
                                    icon: const Icon(Icons.qr_code_rounded, size: 16, color: Color(0xFF94A3B8)),
                                    label: Text(
                                      'Prefer scanning QR Code instead?',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
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

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFCBD5E1),
      ),
    );
  }
}
