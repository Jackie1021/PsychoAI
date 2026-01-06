import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/models/app_theme.dart';

// The global provider for our ThemeService, now using AsyncNotifierProvider
final themeProvider = AsyncNotifierProvider<ThemeService, AppTheme>(() {
  return ThemeService();
});

class ThemeService extends AsyncNotifier<AppTheme> {
  /// The build method is called when the provider is first read.
  /// It's responsible for creating the initial state.
  @override
  Future<AppTheme> build() async {
    // In the future, this method will fetch theme configurations from Firestore.
    return _fetchTheme();
  }

  /// A private method to contain the actual theme fetching logic.
  Future<AppTheme> _fetchTheme() async {
    // Simulate a network delay
    await Future.delayed(const Duration(milliseconds: 200));

    // In this initial step, we load the hardcoded default theme.
    return AppTheme.defaultTheme();
  }

  /// An example method to show how to reload the theme manually.
  Future<void> reloadTheme() async {
    // Set state to loading
    state = const AsyncValue.loading();
    // Re-fetch the theme and update the state, guarding against errors.
    state = await AsyncValue.guard(() async {
      return _fetchTheme();
    });
  }
}
