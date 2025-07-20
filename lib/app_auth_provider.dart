// app_auth_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String? _userRole;

  User? get currentUser => _currentUser;
  String? get userRole => _userRole;

  AppAuthProvider() {
    autoLogin();
  }

  Future<void> autoLogin() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      await _fetchUserRole();
    }
    notifyListeners();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
    if (userDoc.exists) {
      _userRole = userDoc.get('role');
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password, String requiredRole) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = result.user;
      await _fetchUserRole();

      // Verify the user has the required role
      if (_userRole != requiredRole) {
        await _auth.signOut();
        _currentUser = null;
        _userRole = null;
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = result.user;
      
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _userRole = role;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _userRole = null;
    notifyListeners();
  }
}