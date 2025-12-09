import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';

/// Repository for notification operations - syncs with web app's `notifications` collection
class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to notifications collection (same as web app)
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  /// Get stream of notifications for a user (real-time sync with web app)
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();

      // Sort by timestamp descending (newest first) - same as web app
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    });
  }

  /// Get unread notification count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'read': true,
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }

  /// Create a notification (for local triggers - same structure as web app)
  Future<void> createNotification({
    required String userId,
    required String message,
    required NotificationType type,
    String? listingId,
  }) async {
    await _notificationsRef.add({
      'userId': userId,
      'message': message,
      'type': type.name,
      'listingId': listingId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}
