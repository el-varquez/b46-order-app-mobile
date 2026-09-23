import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void toggle(Brightness platformBrightness) {
    final dark =
        state == ThemeMode.dark ||
        (state == ThemeMode.system && platformBrightness == Brightness.dark);
    emit(dark ? ThemeMode.light : ThemeMode.dark);
  }
}
