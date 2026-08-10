import 'package:flutter/material.dart';

/// Paleta del design system "🔥 fuego".
class AppColors {
  AppColors._();

  // --- Acento (fuego) ---
  static const ember = Color(0xFFFF6B35); // acento principal
  static const emberDim = Color(0xFFCC4E1A); // pressed / hover
  static const emberGlow = Color(0xFFFF9A6C); // highlights

  // --- Superficies (dark) ---
  static const surface900 = Color(0xFF0F0F14); // fondo base
  static const surface800 = Color(0xFF1A1A24); // tarjetas
  static const surface700 = Color(0xFF24242F); // elevados
  static const surface600 = Color(0xFF2E2E3D); // bordes / divisores

  // --- Texto (dark) ---
  static const textPrimary = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF9090A8);
  static const textHint = Color(0xFF5A5A70);

  // --- Superficies (light, derivadas) ---
  static const lightBg = Color(0xFFF5F5FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFECECF2);
  static const lightTextPrimary = Color(0xFF15151D);
  static const lightTextSecondary = Color(0xFF55556A);

  // --- Por módulo ---
  static const prodeColor = Color(0xFF34D399); // verde
  static const expensesColor = Color(0xFF60A5FA); // azul
  static const juntadasColor = Color(0xFFFF6B35); // naranja
  static const statsColor = Color(0xFFA78BFA); // violeta
  static const partidosColor = Color(0xFFF4C430); // dorado (cartas FUT)

  static const danger = Color(0xFFEF4444);
}
