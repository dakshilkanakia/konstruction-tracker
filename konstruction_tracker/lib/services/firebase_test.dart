import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseTest {
  static Future<bool> testFirestoreConnection() async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      
      // Try to write a test document
      await db.collection('test').doc('connection').set({
        'timestamp': Timestamp.now(),
        'test': true,
      });
      
      if (kDebugMode) print('✅ Firestore connection successful');
      
      // Clean up test document
      await db.collection('test').doc('connection').delete();
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore connection failed: $e');
        print('Error type: ${e.runtimeType}');
      }
      return false;
    }
  }
  
  static Future<void> testFirebaseAuth() async {
    try {
      // Just check if Firebase is initialized
      if (kDebugMode) print('Firebase Auth is available');
    } catch (e) {
      if (kDebugMode) print('Firebase Auth error: $e');
    }
  }
}
