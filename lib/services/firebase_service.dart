import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      final filePath =
          '${ApiConfig.syllabusStoragePath}/$userPath/${timestamp}_$fileName';

      print('Uploading file to: $filePath');

      // Upload file
      final ref = storage.ref().child(filePath);
      final uploadTask = ref.putFile(file);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
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
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      final userCredential = await auth.signInAnonymously();
      print('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      throw Exception('Failed to sign in anonymously: $e');
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Signed in with email: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      } else {
        throw Exception(e.message ?? 'Login failed');
      }
    } catch (e) {
      print('Error signing in with email: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Register with email and password
  Future<User?> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      print('Registered user: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists with this email');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else {
        throw Exception(e.message ?? 'Registration failed');
      }
    } catch (e) {
      print('Error registering user: $e');
      throw Exception('Failed to register: $e');
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Sign-in canceled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await auth.signInWithCredential(credential);
      print('Signed in with Google: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      await auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else {
        throw Exception(e.message ?? 'Failed to send reset email');
      }
    } catch (e) {
      print('Error sending password reset email: $e');
      throw Exception('Failed to send reset email: $e');
    }
  }

  /// Change password for current user
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    final user = auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    try {
      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
      print('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      } else {
        throw Exception(e.message ?? 'Failed to change password');
      }
    } catch (e) {
      print('Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (!_initialized) {
      throw Exception('Firebase not initialized');
    }

    final user = auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();
      print('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get current user
  User? get currentUser => _initialized ? auth.currentUser : null;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Sign out
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn().signOut(); // Sign out from Google as well
      await auth.signOut();
      print('Signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
