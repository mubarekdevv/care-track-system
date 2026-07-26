import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 📸 Upload child photo from mobile/desktop File
  Future<String> uploadChildPhotoFromFile(String childId, File file) async {
    try {
      Reference ref = _storage.ref().child('child_photos').child('$childId.jpg');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.timeout(const Duration(seconds: 45));
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file to storage: $e");
      rethrow;
    }
  }

  Future<String> uploadChildPhotoFromBytes(String childId, Uint8List bytes) async {
    try {
      Reference ref = _storage.ref().child('child_photos').child('$childId.jpg');
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask.timeout(const Duration(seconds: 45));
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading bytes to storage: $e");
      rethrow;
    }
  }

  Future<String> uploadUserPhotoFromFile(String uid, File file) async {
    try {
      Reference ref = _storage.ref().child('user_photos').child('$uid.jpg');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.timeout(const Duration(seconds: 45));
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading user photo file: $e");
      rethrow;
    }
  }

  Future<String> uploadUserPhotoFromBytes(String uid, Uint8List bytes) async {
    try {
      Reference ref = _storage.ref().child('user_photos').child('$uid.jpg');
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask.timeout(const Duration(seconds: 45));
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading user photo bytes: $e");
      rethrow;
    }
  }
}
