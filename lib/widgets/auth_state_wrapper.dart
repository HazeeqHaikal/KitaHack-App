import 'package:flutter/material.dart';
import 'package:due/services/firebase_service.dart';

/// Wrapper widget that listens to authentication state changes
/// and redirects to login screen if user is unexpectedly signed out
class AuthStateWrapper extends StatefulWidget {
  final Widget child;

  const AuthStateWrapper({super.key, required this.child});

  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  final _firebaseService = FirebaseService();
  bool _wasSignedIn = false;

  @override
  void initState() {
    super.initState();
    _wasSignedIn = _firebaseService.isSignedIn;
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    // Only listen to Firebase auth changes if Firebase is available
    if (!_firebaseService.isAvailable) {
      print('Firebase not available - auth state monitoring disabled');
      return;
    }

    _firebaseService.authStateChanges.listen((user) {
      if (!mounted) return;

      // Check if user is actually signed in (including Google Sign-In)
      final isSignedIn = _firebaseService.isSignedIn;

      // If user was signed in but is now not signed in (unexpected sign-out)
      if (_wasSignedIn && !isSignedIn) {
        print('User unexpectedly signed out - redirecting to login');
        _handleUnexpectedSignOut();
      }

      _wasSignedIn = isSignedIn;
    });
  }

  void _handleUnexpectedSignOut() {
    // Navigate to login screen and clear navigation stack
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

      // Show a message to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please sign in again.'),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
