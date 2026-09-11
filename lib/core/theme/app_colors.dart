import 'package:flutter/material.dart';

class AppColors {
  // Brand & Backgrounds
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color accent = Color(0xFF4F46E5); // Vibrant Indigo
  static const Color accentLight = Color(0xFF6366F1);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color bgLight = Color(0xFFF8FAFC); // Clean dashboard canvas
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Luxury Dark Accents (for hero cards & headers)
  static const Color darkBg = Color(0xFF0A0F1D);
  static const Color darkCard = Color(0xFF111827);
  static const Color darkCardBorder = Color(0xFF1E293B);

  // Status & Timer Colors
  static const Color workingGreen = Color(0xFF10B981); // Emerald Green
  static const Color workingGreenBg = Color(0xFFECFDF5);
  static const Color workingGreenBorder = Color(0xFFA7F3D0);

  static const Color extraOrange = Color(0xFFF97316); // Warm Amber/Orange
  static const Color extraOrangeBg = Color(0xFFFFF7ED);
  static const Color extraOrangeBorder = Color(0xFFFED7AA);

  static const Color totalBlue = Color(0xFF0284C7); // Sky Blue
  static const Color totalBlueBg = Color(0xFFF0F9FF);
  static const Color totalBlueBorder = Color(0xFFBAE6FD);

  static const Color remainingPurple = Color(0xFF9333EA); // Purple / Violet
  static const Color remainingPurpleBg = Color(0xFFFAF5FF);
  static const Color remainingPurpleBorder = Color(0xFFE9D5FF);

  static const Color offlineRed = Color(0xFFEF4444); // Rose Red
  static const Color offlineRedBg = Color(0xFFFEF2F2);
  static const Color offlineRedBorder = Color(0xFFFECACA);

  static const Color pauseAmber = Color(0xFFF59E0B);
  static const Color pauseAmberBg = Color(0xFFFFFBEB);
  static const Color pauseAmberBorder = Color(0xFFFDE68A);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Premium Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF0F172A),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F46E5),
      Color(0xFF7C3AED),
    ],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD97706),
      Color(0xFFF59E0B),
    ],
  );

  static const LinearGradient roseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDC2626),
      Color(0xFFF43F5E),
    ],
  );

  // Ambient Drop Shadow Presets
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> luxuryShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.25}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
