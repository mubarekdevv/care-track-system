import '../../models/app_notification_model.dart';

abstract class NotificationRepository {
  Stream<List<AppNotificationModel>> watchNotifications(String recipientId);
  Future<void> markRead(String notificationId);
  Future<void> markAllRead(String recipientId);
  Future<void> createNotification(AppNotificationModel notification);
}
