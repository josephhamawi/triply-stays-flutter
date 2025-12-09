import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/notification_repository.dart';
import '../../../domain/entities/app_notification.dart';
import '../auth/auth_provider.dart';

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider for user's notifications stream (real-time sync with web app)
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsStream(userId);
});

/// Provider for unread notification count (for badge display)
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return Stream.value(0);
  }

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCountStream(userId);
});

/// State notifier for notification actions
class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final authState = _ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    state = const AsyncValue.loading();

    try {
      await _repository.markAllAsRead(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();

    try {
      await _repository.deleteNotification(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for NotificationNotifier
final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository, ref);
});
