import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/firestore/firestore_doctor_matching_repository.dart';
import '../models/chat_message_model.dart';
import '../models/child_model.dart';
import '../models/message_thread_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class MessagingProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<MessageThread> _threads = [];
  List<ChatMessage> _activeMessages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _activeThreadId;
  StreamSubscription<List<MessageThread>>? _threadsSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  List<MessageThread> get threads => List.unmodifiable(_threads);
  List<ChatMessage> get activeMessages => List.unmodifiable(_activeMessages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  int unreadCountFor(String userId) =>
      _threads.where((thread) => thread.isUnreadFor(userId)).length;

  void startListeningForParent(String parentId) {
    _listen(_db.getMessageThreadsForParent(parentId));
  }

  void startListeningForTeacher(String teacherId) {
    _listen(_db.getMessageThreadsForTeacher(teacherId));
  }

  void startListeningForHealthcare(String doctorId) {
    startListeningForTeacher(doctorId);
  }

  void startListeningForStudent(String studentUserId) {
    _listen(_db.getMessageThreadsForStudent(studentUserId));
  }

  void _listen(Stream<List<MessageThread>> stream) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _threadsSubscription?.cancel();
    _threadsSubscription = stream.listen(
      (data) {
        _threads = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void watchThreadMessages(String threadId) {
    if (_activeThreadId == threadId) return;
    _activeThreadId = threadId;
    _activeMessages = [];

    _messagesSubscription?.cancel();
    _messagesSubscription = _db.getChatMessages(threadId).listen(
      (messages) {
        _activeMessages = messages;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        notifyListeners();
      },
    );
  }

  void stopWatchingMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _activeThreadId = null;
    _activeMessages = [];
  }

  /// Teachers linked to the child's class section.
  Future<List<UserModel>> teachersForChild(ChildModel child) async {
    final classId = child.classRoomId;
    if (classId == null || classId.isEmpty) return [];
    return _db.getTeachersForClassRoom(classId);
  }

  /// Unique parent contacts from teacher's class roster.
  Future<List<ParentContact>> parentContactsFromRoster(
    List<StudentModel> roster,
  ) async {
    final byParent = <String, ParentContact>{};
    for (final student in roster) {
      if (student.parentId.isEmpty) continue;
      if (byParent.containsKey(student.parentId)) {
        final existing = byParent[student.parentId]!;
        final names = [...existing.studentNames];
        if (!names.contains(student.fullName)) {
          names.add(student.fullName);
        }
        byParent[student.parentId] = ParentContact(
          parentId: existing.parentId,
          parentName: existing.parentName,
          studentNames: names,
          studentId: existing.studentId,
          classRoomId: existing.classRoomId ?? student.classRoomId,
        );
        continue;
      }
      final parent = await _db.getUserById(student.parentId);
      byParent[student.parentId] = ParentContact(
        parentId: student.parentId,
        parentName: parent?.fullName ?? 'Parent',
        studentNames: [student.fullName],
        studentId: student.id,
        classRoomId: student.classRoomId,
      );
    }
    final list = byParent.values.toList();
    list.sort((a, b) => a.parentName.compareTo(b.parentName));
    return list;
  }

  Future<MessageThread?> ensureThread({
    required String parentId,
    required String parentName,
    required UserModel teacher,
    required ChildModel child,
  }) async {
    _errorMessage = null;
    final classId = child.classRoomId ?? '';
    if (classId.isEmpty) {
      _errorMessage = 'Enroll ${child.name} in a class before messaging teachers.';
      notifyListeners();
      return null;
    }

    final teachers = await teachersForChild(child);
    if (!teachers.any((t) => t.uid == teacher.uid)) {
      _errorMessage = '${teacher.fullName} is not assigned to ${child.name}\'s class.';
      notifyListeners();
      return null;
    }

    final existing = await _db.findThreadForParticipants(
      parentId: parentId,
      teacherId: teacher.uid,
      studentId: child.id,
    );
    if (existing != null) return existing;

    final thread = MessageThread(
      id: '',
      parentId: parentId,
      teacherId: teacher.uid,
      parentName: parentName,
      teacherName: teacher.fullName,
      lastMessage: 'Conversation started',
      lastMessageAt: DateTime.now(),
      studentId: child.id,
      studentName: child.name,
      classRoomId: classId,
    );

    final id = await _db.createMessageThread(thread);
    return MessageThread(
      id: id,
      parentId: thread.parentId,
      teacherId: thread.teacherId,
      parentName: thread.parentName,
      teacherName: thread.teacherName,
      lastMessage: thread.lastMessage,
      lastMessageAt: thread.lastMessageAt,
      studentId: thread.studentId,
      studentName: thread.studentName,
      classRoomId: thread.classRoomId,
    );
  }

  Future<MessageThread?> ensureTeacherToParentThread({
    required UserModel teacher,
    required ParentContact contact,
  }) async {
    _errorMessage = null;

    final existing = await _db.findThreadForParticipants(
      parentId: contact.parentId,
      teacherId: teacher.uid,
      studentId: contact.studentId,
    );
    if (existing != null) return existing;

    final thread = MessageThread(
      id: '',
      parentId: contact.parentId,
      teacherId: teacher.uid,
      parentName: contact.parentName,
      teacherName: teacher.fullName,
      lastMessage: 'Conversation started',
      lastMessageAt: DateTime.now(),
      studentId: contact.studentId,
      studentName: contact.studentNames.first,
      classRoomId: contact.classRoomId,
    );

    final id = await _db.createMessageThread(thread);
    return MessageThread(
      id: id,
      parentId: thread.parentId,
      teacherId: thread.teacherId,
      parentName: thread.parentName,
      teacherName: thread.teacherName,
      lastMessage: thread.lastMessage,
      lastMessageAt: thread.lastMessageAt,
      studentId: thread.studentId,
      studentName: thread.studentName,
      classRoomId: thread.classRoomId,
    );
  }

  /// School doctors assigned to a child (parent messaging).
  Future<List<UserModel>> assignedDoctorsForChild(ChildModel child) async {
    if (child.usesPrivateDoctor) return [];
    final repo = FirestoreDoctorMatchingRepository();
    final assignments =
        await repo.watchAssignmentsForStudent(child.id).first;
    final doctors = <UserModel>[];
    final seen = <String>{};
    for (final assignment in assignments) {
      if (!seen.add(assignment.doctorId)) continue;
      final user = await repo.getUser(assignment.doctorId);
      if (user != null) doctors.add(user);
    }
    return doctors;
  }

  /// Parent contacts from a doctor's assigned patient list.
  Future<List<HealthcareParentContact>> parentContactsFromPatients(
    List<ChildModel> patients,
  ) async {
    final byParent = <String, HealthcareParentContact>{};
    for (final patient in patients) {
      if (patient.parentId.isEmpty) continue;
      if (byParent.containsKey(patient.parentId)) continue;
      final parent = await _db.getUserById(patient.parentId);
      byParent[patient.parentId] = HealthcareParentContact(
        parentId: patient.parentId,
        parentName: parent?.fullName ?? 'Parent',
        studentId: patient.id,
        studentName: patient.name,
      );
    }
    final list = byParent.values.toList();
    list.sort((a, b) => a.parentName.compareTo(b.parentName));
    return list;
  }

  Future<MessageThread?> ensureHealthcareToParentThread({
    required UserModel doctor,
    required HealthcareParentContact contact,
  }) async {
    final child = ChildModel(
      id: contact.studentId,
      name: contact.studentName,
      age: 0,
      parentId: contact.parentId,
      imageUrl: '',
    );
    return ensureDoctorParentThread(
      parentId: contact.parentId,
      parentName: contact.parentName,
      doctor: doctor,
      child: child,
      specialtyLabel: 'School clinic',
    );
  }

  Future<MessageThread?> ensureHealthcareToStudentThread({
    required UserModel doctor,
    required ChildModel child,
  }) async {
    _errorMessage = null;
    final studentUserId = child.studentUserId;
    if (studentUserId == null || studentUserId.isEmpty) {
      _errorMessage =
          '${child.name} has not linked their student login yet. Message the parent instead.';
      notifyListeners();
      return null;
    }

    final existing = await _db.findThreadForParticipants(
      parentId: studentUserId,
      teacherId: doctor.uid,
      studentId: child.id,
      threadType: 'healthcare_student',
    );
    if (existing != null) return existing;

    final thread = MessageThread(
      id: '',
      parentId: studentUserId,
      teacherId: doctor.uid,
      parentName: child.name,
      teacherName: doctor.fullName,
      lastMessage: 'Clinic follow-up started',
      lastMessageAt: DateTime.now(),
      studentId: child.id,
      studentName: child.name,
      threadType: 'healthcare_student',
    );

    final id = await _db.createMessageThread(thread);
    return MessageThread(
      id: id,
      parentId: thread.parentId,
      teacherId: thread.teacherId,
      parentName: thread.parentName,
      teacherName: thread.teacherName,
      lastMessage: thread.lastMessage,
      lastMessageAt: thread.lastMessageAt,
      studentId: thread.studentId,
      studentName: thread.studentName,
      threadType: thread.threadType,
    );
  }

  Future<MessageThread?> ensureDoctorParentThread({
    required String parentId,
    required String parentName,
    required UserModel doctor,
    required ChildModel child,
    required String specialtyLabel,
  }) async {
    _errorMessage = null;

    final existing = await _db.findThreadForParticipants(
      parentId: parentId,
      teacherId: doctor.uid,
      studentId: child.id,
      threadType: 'healthcare',
    );
    if (existing != null) return existing;

    final thread = MessageThread(
      id: '',
      parentId: parentId,
      teacherId: doctor.uid,
      parentName: parentName,
      teacherName: doctor.fullName,
      lastMessage: 'Health follow-up started ($specialtyLabel)',
      lastMessageAt: DateTime.now(),
      studentId: child.id,
      studentName: child.name,
      threadType: 'healthcare',
    );

    final id = await _db.createMessageThread(thread);
    return MessageThread(
      id: id,
      parentId: thread.parentId,
      teacherId: thread.teacherId,
      parentName: thread.parentName,
      teacherName: thread.teacherName,
      lastMessage: thread.lastMessage,
      lastMessageAt: thread.lastMessageAt,
      studentId: thread.studentId,
      studentName: thread.studentName,
      threadType: thread.threadType,
    );
  }

  /// @deprecated Use [ensureThread] with child + teacher selection.
  Future<MessageThread?> ensureParentTeacherThread({
    required String parentId,
    required String parentName,
  }) async {
    _errorMessage =
        'Select a child and their class teacher to start a conversation.';
    notifyListeners();
    return null;
  }

  Future<void> sendMessage({
    required MessageThread thread,
    required UserModel sender,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isSending = true;
    notifyListeners();

    try {
      final message = ChatMessage(
        id: '',
        threadId: thread.id,
        senderId: sender.uid,
        senderRole: sender.role,
        senderName: sender.fullName,
        text: trimmed,
        createdAt: DateTime.now(),
      );

      await _db.sendChatMessage(
        threadId: thread.id,
        message: message,
        senderIsParent: sender.role == 'Parent' || sender.role == 'Child',
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> markThreadRead({
    required MessageThread thread,
    required String userId,
  }) async {
    if (!thread.isUnreadFor(userId)) return;
    try {
      await _db.markThreadRead(
        threadId: thread.id,
        forParent: userId == thread.parentId,
      );
    } catch (e) {
      debugPrint('markThreadRead error: $e');
    }
  }

  void stopListening() {
    _threadsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _threadsSubscription = null;
    _messagesSubscription = null;
    _threads = [];
    _activeMessages = [];
    _activeThreadId = null;
    _isLoading = false;
    _isSending = false;
    _errorMessage = null;
    notifyListeners();
  }
}

class HealthcareParentContact {
  final String parentId;
  final String parentName;
  final String studentId;
  final String studentName;

  HealthcareParentContact({
    required this.parentId,
    required this.parentName,
    required this.studentId,
    required this.studentName,
  });

  String get subtitle => 'Parent of $studentName';
}

class ParentContact {
  final String parentId;
  final String parentName;
  final List<String> studentNames;
  final String studentId;
  final String? classRoomId;

  ParentContact({
    required this.parentId,
    required this.parentName,
    required this.studentNames,
    required this.studentId,
    this.classRoomId,
  });

  String get subtitle =>
      studentNames.length == 1 ? 'Parent of ${studentNames.first}' : '${studentNames.length} children in your class';
}
