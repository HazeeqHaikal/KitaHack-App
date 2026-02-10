import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:due/config/api_config.dart';
import 'package:due/firebase_options.dart';
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
  bool _authInitialized = false; // Track if auth/sign-in is ready
  bool _initializationAttempted = false;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<User?>? _authStateSubscription;
  String? _lastInitError;

  /// Initialize Firebase
  /// Call this once at app startup
  Future<void> initialize() async {
    if (_initialized && _authInitialized) return;

    _initializationAttempted = true;

    // Try to initialize Firebase Core with platform-specific options
    if (!_initialized) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _initialized = true;
        _lastInitError = null;
        print('Firebase core initialized successfully');

        // Set up auth state persistence (enabled by default)
        try {
          await auth.setPersistence(Persistence.LOCAL);
          print('Auth persistence enabled');
        } catch (e) {
          print('Auth persistence error (non-critical): $e');
        }
      } catch (e) {
        _lastInitError = e.toString();
        print('Firebase core initialization error: $e');
        print('The app will continue with limited functionality');
        _initialized = false;
      }
    }

    // Initialize Google Sign-In even if Firebase core fails
    // This allows authentication to work independently
    if (_googleSignIn == null) {
      try {
        _googleSignIn = GoogleSignIn(scopes: ApiConfig.calendarScopes);
        _authInitialized = true;
        print('Google Sign-In initialized successfully');
      } catch (e) {
        print('Google Sign-In initialization error: $e');
        _authInitialized = false;
      }
    }
  }

  /// Retry Firebase initialization (useful if it failed on startup)
  Future<bool> retryInitialization() async {
    if (_initialized) return true;

    print('Retrying Firebase initialization...');
    _initializationAttempted = false;
    _initialized = false;
    await initialize();
    return _initialized;
  }

  /// Check if Firebase is initialized and available
  bool get isAvailable => _initialized;

  /// Check if authentication is available
  bool get isAuthAvailable => _authInitialized;

  /// Get the last initialization error message
  String? get lastInitError => _lastInitError;

  /// Check if initialization was attempted
  bool get initializationAttempted => _initializationAttempted;

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

      if (userId == null || userId.isEmpty) {
        throw Exception('User must be signed in to upload files');
      }

      final userPath = userId;

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

  /// Get GoogleSignIn instance for calendar sync
  GoogleSignIn? get googleSignIn => _googleSignIn;

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    if (!_authInitialized) {
      throw Exception(
        'Google Sign-In not initialized. Please restart the app.',
      );
    }

    try {
      // Trigger the authentication flow with calendar scopes
      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Sign-in canceled by user');
      }

      // Try to initialize Firebase if it failed earlier
      if (!_initialized) {
        print('Firebase not initialized, attempting to initialize now...');
        final retrySuccess = await retryInitialization();

        if (!retrySuccess) {
          // Firebase still not working, sign out from Google and throw error
          await _googleSignIn?.signOut();
          throw Exception(
            'Unable to complete sign-in. Please check your internet connection and try again.',
          );
        }
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
      // Sign out from Google to clean up state
      await _googleSignIn?.signOut();
      rethrow;
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

  /// Stream of auth state changes
  Stream<User?> get authStateChanges =>
      _initialized ? auth.authStateChanges() : Stream.value(null);

  /// Sign out (optimized for faster response)
  Future<void> signOut() async {
    if (!_authInitialized) return;
    try {
      // Sign out from both services in parallel for faster response
      final futures = <Future>[
        if (_googleSignIn != null) _googleSignIn!.signOut(),
      ];

      if (_initialized) {
        futures.add(auth.signOut());
      }

      await Future.wait(futures, eagerError: true);
      print('Signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      // Force sign out even if there are errors
      try {
        await _googleSignIn?.signOut();
        if (_initialized) await auth.signOut();
      } catch (e2) {
        print('Force sign out error: $e2');
      }
      rethrow;
    }
  }

  /// Sign out from Google only (for calendar disconnect)
  Future<void> signOutGoogle() async {
    if (!_initialized) return;
    try {
      await _googleSignIn?.signOut();
      print('Signed out from Google');
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateSubscription?.cancel();
  }
}
