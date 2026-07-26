import 'package:intl/intl.dart';

class MessageThread {
  final String id;
  final String parentId;
  final String teacherId;
  final String parentName;
  final String teacherName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String? studentId;
  final String? studentName;
  final String? classRoomId;
  final String threadType;
  final bool unreadByParent;
  final bool unreadByTeacher;

  const MessageThread({
    required this.id,
    required this.parentId,
    required this.teacherId,
    required this.parentName,
    required this.teacherName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.studentId,
    this.studentName,
    this.classRoomId,
    this.threadType = 'teacher',
    this.unreadByParent = false,
    this.unreadByTeacher = false,
  });

  bool get isHealthcareStudentThread => threadType == 'healthcare_student';

  bool get isHealthcareThread =>
      threadType == 'healthcare' || threadType == 'healthcare_student';

  String? get contextLabel {
    if (studentName != null && studentName!.isNotEmpty) {
      if (isHealthcareStudentThread) {
        return 'Clinic chat: $studentName';
      }
      return isHealthcareThread
          ? 'Health follow-up: $studentName'
          : 'Re: $studentName';
    }
    return isHealthcareThread ? 'Health follow-up' : null;
  }

  bool isUnreadFor(String userId) {
    if (userId == parentId) return unreadByParent;
    if (userId == teacherId) return unreadByTeacher;
    return false;
  }

  String otherPartyName(String userId) {
    return userId == parentId ? teacherName : parentName;
  }

  String timeLabel({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(lastMessageAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return DateFormat('h:mm a').format(lastMessageAt);
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(lastMessageAt);
  }

  factory MessageThread.fromMap(Map<String, dynamic> map, String id) {
    DateTime lastAt = DateTime.now();
    final raw = map['lastMessageAt'];
    if (raw is String) {
      lastAt = DateTime.tryParse(raw) ?? lastAt;
    }

    return MessageThread(
      id: id,
      parentId: map['parentId']?.toString() ?? '',
      teacherId: map['teacherId']?.toString() ?? '',
      parentName: map['parentName']?.toString() ?? 'Parent',
      teacherName: map['teacherName']?.toString() ?? 'Teacher',
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageAt: lastAt,
      studentId: map['studentId'] as String?,
      studentName: map['studentName'] as String?,
      classRoomId: map['classRoomId'] as String?,
      threadType: map['threadType'] as String? ?? 'teacher',
      unreadByParent: map['unreadByParent'] == true,
      unreadByTeacher: map['unreadByTeacher'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'teacherId': teacherId,
      'parentName': parentName,
      'teacherName': teacherName,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      if (studentId != null) 'studentId': studentId,
      if (studentName != null) 'studentName': studentName,
      if (classRoomId != null) 'classRoomId': classRoomId,
      'threadType': threadType,
      'unreadByParent': unreadByParent,
      'unreadByTeacher': unreadByTeacher,
    };
  }
}
