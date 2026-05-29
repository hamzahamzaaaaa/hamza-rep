import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/colors.dart';

class ThemeState {
  final ThemeMode mode;
  final bool isDark;
  final bool isDeepBlack;

  ThemeState({required this.mode, required this.isDark, this.isDeepBlack = false});
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(mode: ThemeMode.dark, isDark: true, isDeepBlack: false));

  void setLight() {
    AppColors.setToLight();
    state = ThemeState(mode: ThemeMode.light, isDark: false, isDeepBlack: false);
  }

  void setDark() {
    AppColors.setToDark();
    state = ThemeState(mode: ThemeMode.dark, isDark: true, isDeepBlack: false);
  }

  void setDeepBlack() {
    AppColors.setToDeepBlack();
    state = ThemeState(mode: ThemeMode.dark, isDark: true, isDeepBlack: true);
  }

  void toggleTheme() {
    if (state.isDark) {
      setLight();
    } else {
      setDark();
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
