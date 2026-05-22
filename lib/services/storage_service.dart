import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 📸 Upload child photo from mobile/desktop File
  Future<String> uploadChildPhotoFromFile(String childId, File file) async {
    try {
      Reference ref = _storage.ref().child('child_photos').child('$childId.jpg');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file to storage: $e");
      rethrow;
    }
  }

  // 🌐 Upload child photo from Web or raw platform bytes (Uint8List)
  Future<String> uploadChildPhotoFromBytes(String childId, Uint8List bytes) async {
    try {
      Reference ref = _storage.ref().child('child_photos').child('$childId.jpg');
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask = ref.putData(bytes, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading bytes to storage: $e");
      rethrow;
    }
  }
}
