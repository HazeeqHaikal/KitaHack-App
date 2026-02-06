import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:due/config/api_config.dart';
import 'package:path/path.dart' as path;

/// Service for Firebase operations
/// Handles file storage and authentication
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  bool _initialized = false;

  /// Initialize Firebase
  /// Call this once at app startup
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _initialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
      // Continue without Firebase - app can still work with Gemini only
      _initialized = false;
    }
  }

  /// Check if Firebase is initialized and available
  bool get isAvailable => _initialized;

  /// Upload a file to Firebase Storage
  /// 
  /// [file] - The file to upload
  /// [userId] - Optional user ID for organizing files
  /// Returns the download URL of the uploaded file
  Future<String> uploadFile(File file, {String? userId}) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized. File storage unavailable.');
    }

    try {
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userPath = userId ?? 'anonymous';
      
      // Create unique file path
      final filePath = '${ApiConfig.syllabusStoragePath}/$userPath/$timestamp\_$fileName';
      
      print('Uploading file to: $filePath');
      
      // Upload file
      final ref = storage.ref().child(filePath);
      final uploadTask = ref.putFile(file);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(1)}%');
      });
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('File uploaded successfully: $downloadUrl');
      
      return downloadUrl;
      
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    if (!_initialized) return;

    try {
      final ref = storage.refFromURL(downloadUrl);
      await ref.delete();
      print('File deleted: $downloadUrl');
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  /// Sign in anonymously for basic file storage
  /// This allows users to use the app without creating an account
  Future<User?> signInAnonymously() async {
    if (!_initialized) return null;

    try {
      final userCredential = await auth.signInAnonymously();
      print('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  /// Get current user
  User? get currentUser => _initialized ? auth.currentUser : null;

  /// Sign out
  Future<void> signOut() async {
    if (!_initialized) return;
    await auth.signOut();
  }
}
