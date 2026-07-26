import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';

/// **DEPRECATED — Phase 2.** Duplicate of [DatabaseService]. Will be deleted in Phase 3.
@Deprecated('Use DatabaseService or StudentRepository instead.')
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addChild(ChildModel child) {
    return _db.collection('children').add(child.toMap());
  }

  Stream<List<ChildModel>> getChildren(String parentId) {
    return _db
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
