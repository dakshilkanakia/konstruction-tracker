import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String?> uploadReceiptImage(File imageFile, String projectId) async {
    try {
      // Compress the image
      File compressedFile = await _compressImage(imageFile);
      
      // Generate unique filename
      String fileName = '${_uuid.v4()}.jpg';
      String path = 'receipts/$projectId/$fileName';
      
      // Upload to Firebase Storage
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(compressedFile);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up compressed file
      await compressedFile.delete();
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> deleteReceiptImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting image: $e');
      return false;
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      // Read the image
      img.Image? image = img.decodeImage(await file.readAsBytes());
      if (image == null) return file;

      // Resize image if it's too large (max width 1024px)
      if (image.width > 1024) {
        image = img.copyResize(image, width: 1024);
      }

      // Compress as JPEG with 85% quality
      List<int> compressedBytes = img.encodeJpg(image, quality: 85);

      // Create temporary file
      String tempPath = '${file.parent.path}/compressed_${_uuid.v4()}.jpg';
      File compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      if (kDebugMode) print('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }
}
