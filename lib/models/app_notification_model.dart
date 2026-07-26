import '../core/domain/domain_enums.dart';

class AppNotificationModel {
  final String id;
  final String recipientId;
  final String recipientRole;
  final NotificationType type;
  final String title;
  final String body;
  final String? relatedStudentId;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.type,
    required this.title,
    required this.body,
    this.relatedStudentId,
    this.relatedEntityId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      id: id,
      recipientId: map['recipientId'] as String? ?? '',
      recipientRole: map['recipientRole'] as String? ?? '',
      type: NotificationType.fromId(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      relatedStudentId: map['relatedStudentId'] as String?,
      relatedEntityId: map['relatedEntityId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'recipientId': recipientId,
        'recipientRole': recipientRole,
        'type': type.id,
        'title': title,
        'body': body,
        if (relatedStudentId != null) 'relatedStudentId': relatedStudentId,
        if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
        'isRead': isRead,
        'createdAt': createdAt,
      };
}
