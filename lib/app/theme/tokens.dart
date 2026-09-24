import 'package:flutter/material.dart';

abstract final class PopColors {
  static const authInk = Color(0xFF19100E);
  static const authDarkInk = Color(0xFFFFF7EC);
  static const authSoft = Color(0xFFF7DAC7);
  static const authDarkSoft = Color(0xFF503126);
  static const authDanger = Color(0xFFC91427);
  static const authDarkDanger = Color(0xFFFF6D7B);
  // Prototype palette; scoped to authentication screens.
  static const launchRed = Color(0xFFF10F24);
  static const launchBackground = Color(0xFF211714);
  static const launchSurface = Color(0xFF38241E);
  static const launchOutline = Color(0xFF624235);
  static const launchMuted = Color(0xFFD0B6A8);
  static const launchLightOutline = Color(0xFFEBCDBD);
  static const launchLightMuted = Color(0xFF78645C);
  static const launchShadow = Color(0xFF080808);
  static const brandRed = Color(0xFFF80D2C);
  static const brandRedDark = Color(0xFFC90822);
  static const ink = Color(0xFF211613);
  static const inkSoft = Color(0xFF3A241D);
  static const brown = Color(0xFF694031);
  static const brownSoft = Color(0xFF8A5A48);
  static const cream = Color(0xFFFFF3DF);
  static const creamSoft = Color(0xFFF7E4C8);
  static const paper = Color(0xFFFFFBF4);
  static const muted = Color(0xFFB98F7A);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const success = Color(0xFF23835B);
  static const warning = Color(0xFFC97A13);
}

abstract final class PopSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class PopRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 28.0;
}
