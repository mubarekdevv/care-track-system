import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class ChildProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  List<ChildModel> _children = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ChildModel>>? _childrenSubscription;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 📝 Listen to children profiles in real-time
  void startListeningToChildren(String parentId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _childrenSubscription?.cancel();
    _childrenSubscription = _dbService.getChildrenByParent(parentId).listen(
      (data) {
        _children = data;
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

  // 🚪 Stop listening (e.g. on logout)
  void stopListening() {
    _childrenSubscription?.cancel();
    _childrenSubscription = null;
    _children = [];
    notifyListeners();
  }

  // 🧹 Clear Errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 👶 Add Child Profile with dynamic photo upload
  Future<bool> addChild({
    required String name,
    required int age,
    required String parentId,
    Uint8List? imageBytes,
    File? imageFile,
    List<String> vaccinations = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Generate unique doc reference to obtain ID in advance
      final docRef = FirebaseFirestore.instance.collection('children').doc();
      final childId = docRef.id;

      String imageUrl = '';

      // 2. Upload image if provided
      if (imageBytes != null) {
        imageUrl = await _storageService.uploadChildPhotoFromBytes(childId, imageBytes);
      } else if (imageFile != null) {
        imageUrl = await _storageService.uploadChildPhotoFromFile(childId, imageFile);
      }

      // 3. Create ChildModel
      final child = ChildModel(
        id: childId,
        name: name,
        age: age,
        parentId: parentId,
        imageUrl: imageUrl,
        vaccinations: vaccinations,
      );

      // 4. Save to Firestore using the generated ID (setChild)
      await _dbService.setChild(childId, child);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    super.dispose();
  }
}
