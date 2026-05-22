import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';

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
  Future<void> setChild(String childId, ChildModel child) async {
    try {
      await _db.collection('children').doc(childId).set(child.toMap()).timeout(const Duration(seconds: 10));
      print("Child set successfully!");
    } catch (e) {
      print("Error setting child: $e");
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
}
