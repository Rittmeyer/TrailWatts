import 'package:flutter/material.dart';

/// Design tokens ported 1:1 from the Trailwatt HTML prototype
/// (trailwatt_fluxo.html :root custom properties). Keep this file as the
/// single source of truth - screens should never hardcode a hex value.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF0B2B2B);
  static const primary = Color(0xFF028090);
  static const secondary = Color(0xFF00A896);
  static const accent = Color(0xFF02C39A);
  static const warn = Color(0xFFC77C21);
  static const paper = Color(0xFFF5F7F6);
  static const inkSoft = Color(0xFF5B6B69);
  static const line = Color(0xFFE2E8E6);

  /// A control that is present but cannot act right now. Distinct from
  /// [line] on purpose: a hairline is meant to disappear into the surface,
  /// and borrowing it for a disabled icon made the icon disappear too.
  static const inkDisabled = Color(0xFF9AA5A3);
  static const white = Colors.white;

  static const greenBg = Color(0xFFDCF3EA);
  static const greenText = Color(0xFF0F6E56);
  static const warnBg = Color(0xFFFBEBD6);
  static const warnText = Color(0xFF9C5B12);

  /// Zone palette, shared everywhere training intensity is shown - map,
  /// calendar, workout builder, history. Z1-Z5 are the original five; Z6-Z7
  /// extend the same progression for seven-zone tables, so a zone colour
  /// means the same relative intensity on either scale.
  /// See models/zone.dart (Constitution Article VII).
  static const zone1 = Color(0xFF8FA3AB); // Recuperacao
  static const zone2 = Color(0xFF028090); // Resistencia
  static const zone3 = Color(0xFF02C39A); // Tempo
  static const zone4 = Color(0xFFC77C21); // Limiar
  static const zone5 = Color(0xFFB23A3A); // VO2max
  static const zone6 = Color(0xFF8E2F6E); // Anaerobico
  static const zone7 = Color(0xFF4A2545); // Neuromuscular
}
