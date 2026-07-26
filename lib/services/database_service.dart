import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/domain/domain_enums.dart';
import '../models/chat_message_model.dart';
import '../models/child_model.dart';
import '../models/health_appointment_model.dart';
import '../models/marketplace_order_model.dart';
import '../models/message_thread_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 👶 Function to add a child to the database
  Future<void> addChild(ChildModel child) async {
    try {
      await _db.collection('children').add(child.toMap()).timeout(const Duration(seconds: 10));
      print("Child added successfully!");
    } catch (e) {
      print("Error adding child: $e");
      rethrow;
    }
  }

  // 👶 Function to save a child with a pre-generated ID (useful for photo uploads)
  Future<void> setChild(
    String childId,
    ChildModel child, {
    String? fullName,
    int? schemaVersion,
  }) async {
    try {
      final data = child.toMap();
      if (fullName != null && fullName.isNotEmpty) {
        data['fullName'] = fullName;
        data['name'] = fullName;
      }
      if (schemaVersion != null) {
        data['schemaVersion'] = schemaVersion;
      }
      await _db.collection('children').doc(childId).set(data).timeout(const Duration(seconds: 10));
      print("Child set successfully!");
    } catch (e) {
      print("Error setting child: $e");
      rethrow;
    }
  }

  Future<void> updateChildFields(String childId, Map<String, dynamic> fields) async {
    try {
      await _db.collection('children').doc(childId).update(fields).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error updating child: $e');
      rethrow;
    }
  }

  // 📝 Function to get all children for a specific parent
  Stream<List<ChildModel>> getChildrenByParent(String parentId) {
    return _db
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 🏥 All registered children (healthcare directory)
  Stream<List<ChildModel>> getAllChildren() {
    return _db.collection('children').snapshots().map((snapshot) {
      final children = snapshot.docs
          .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
          .toList();
      children.sort((a, b) => a.name.compareTo(b.name));
      return children;
    });
  }

  Stream<List<HealthAppointment>> getHealthAppointments() {
    return _db
        .collection('health_appointments')
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthAppointment.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addHealthAppointment(HealthAppointment appointment) async {
    await _db
        .collection('health_appointments')
        .add(appointment.toMap())
        .timeout(const Duration(seconds: 10));
  }

  Future<String> placeMarketplaceOrder(Map<String, dynamic> orderData) async {
    final doc = await _db
        .collection('marketplace_orders')
        .add(orderData)
        .timeout(const Duration(seconds: 10));
    return doc.id;
  }

  Stream<List<MarketplaceOrder>> getMarketplaceOrdersForParent(String parentId) {
    return _db
        .collection('marketplace_orders')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => MarketplaceOrder.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Future<UserModel?> getFirstUserByRole(String role) async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: role)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = Map<String, dynamic>.from(doc.data());
    data['uid'] = doc.id;
    return UserModel.fromMap(data);
  }

  Stream<List<MessageThread>> getMessageThreadsForParent(String parentId) {
    return _db
        .collection('message_threads')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map(_mapThreadsSorted);
  }

  Stream<List<MessageThread>> getMessageThreadsForTeacher(String teacherId) {
    return _db
        .collection('message_threads')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map(_mapThreadsSorted);
  }

  Stream<List<MessageThread>> getMessageThreadsForStudent(String studentUserId) {
    return _db
        .collection('message_threads')
        .where('parentId', isEqualTo: studentUserId)
        .where('threadType', isEqualTo: 'healthcare_student')
        .snapshots()
        .map(_mapThreadsSorted);
  }

  List<MessageThread> _mapThreadsSorted(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final threads = snapshot.docs
        .map((doc) => MessageThread.fromMap(doc.data(), doc.id))
        .toList();
    threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return threads;
  }

  Stream<List<ChatMessage>> getChatMessages(String threadId) {
    return _db
        .collection('messages')
        .where('threadId', isEqualTo: threadId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList();
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  Future<String> createMessageThread(MessageThread thread) async {
    final doc = await _db
        .collection('message_threads')
        .add(thread.toMap())
        .timeout(const Duration(seconds: 10));
    return doc.id;
  }

  Future<MessageThread?> findThreadForParent(String parentId) async {
    final snapshot = await _db
        .collection('message_threads')
        .where('parentId', isEqualTo: parentId)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return MessageThread.fromMap(doc.data(), doc.id);
  }

  Future<MessageThread?> findThreadForParticipants({
    required String parentId,
    required String teacherId,
    String? studentId,
    String threadType = 'teacher',
  }) async {
    final snapshot = await _db
        .collection('message_threads')
        .where('parentId', isEqualTo: parentId)
        .where('teacherId', isEqualTo: teacherId)
        .get()
        .timeout(const Duration(seconds: 10));

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['threadType'] as String? ?? 'teacher') != threadType) continue;
      final sid = data['studentId'] as String?;
      if (studentId == null || studentId.isEmpty) {
        if (sid == null || sid.isEmpty) {
          return MessageThread.fromMap(data, doc.id);
        }
      } else if (sid == studentId) {
        return MessageThread.fromMap(data, doc.id);
      }
    }
    return null;
  }

  /// Teachers assigned to a class section (linked accounts only).
  Future<List<UserModel>> getTeachersForClassRoom(String classRoomId) async {
    if (classRoomId.isEmpty) return [];
    final assignments = await _db
        .collection(FirestoreCollections.classSubjects)
        .where('classRoomId', isEqualTo: classRoomId)
        .where('isActive', isEqualTo: true)
        .get()
        .timeout(const Duration(seconds: 10));

    final teacherIds = <String>{};
    for (final doc in assignments.docs) {
      final tid = doc.data()['teacherId'] as String? ?? '';
      if (tid.isNotEmpty) teacherIds.add(tid);
    }
    if (teacherIds.isEmpty) return [];

    final teachers = <UserModel>[];
    for (final tid in teacherIds) {
      final userDoc = await _db.collection('users').doc(tid).get();
      if (!userDoc.exists) continue;
      final data = Map<String, dynamic>.from(userDoc.data()!);
      data['uid'] = userDoc.id;
      teachers.add(UserModel.fromMap(data));
    }
    teachers.sort((a, b) => a.fullName.compareTo(b.fullName));
    return teachers;
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['uid'] = doc.id;
    return UserModel.fromMap(data);
  }

  Future<void> sendChatMessage({
    required String threadId,
    required ChatMessage message,
    required bool senderIsParent,
  }) async {
    final batch = _db.batch();
    final messageRef = _db.collection('messages').doc();
    batch.set(messageRef, message.toMap());

    final threadRef = _db.collection('message_threads').doc(threadId);
    batch.update(threadRef, {
      'lastMessage': message.text,
      'lastMessageAt': message.createdAt.toIso8601String(),
      'unreadByParent': !senderIsParent,
      'unreadByTeacher': senderIsParent,
    });

    await batch.commit().timeout(const Duration(seconds: 10));
  }

  Future<void> markThreadRead({
    required String threadId,
    required bool forParent,
  }) async {
    await _db.collection('message_threads').doc(threadId).update({
      if (forParent) 'unreadByParent': false else 'unreadByTeacher': false,
    }).timeout(const Duration(seconds: 10));
  }
}
