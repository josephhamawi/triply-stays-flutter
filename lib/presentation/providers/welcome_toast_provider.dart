import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to track if welcome toast should be shown
/// The toast is shown once per session after sign-in/sign-up

class WelcomeToastNotifier extends StateNotifier<bool> {
  WelcomeToastNotifier() : super(false);

  static const String _lastShownSessionKey = 'welcome_toast_session';

  /// Mark that welcome toast should be shown
  Future<void> requestShowWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    // Generate a new session ID
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString(_lastShownSessionKey, sessionId);
    state = true;
  }

  /// Mark welcome toast as shown
  void markShown() {
    state = false;
  }

  /// Check if should show welcome (only once per auth event)
  bool get shouldShow => state;
}

final welcomeToastProvider = StateNotifierProvider<WelcomeToastNotifier, bool>(
  (ref) => WelcomeToastNotifier(),
);
