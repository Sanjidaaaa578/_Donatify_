import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'supabase_service.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Donation Request methods
  Future<void> createDonationRequest({
    required String title,
    required String category,
    required double amount,
    required String description,
    required List<String> documentUrls,
    required String userId,
  }) async {
    await _firestore.collection('donation_requests').add({
      'title': title,
      'category': category,
      'targetAmount': amount,
      'currentAmount': 0.0,
      'description': description,
      'status': 'pending',
      'isImportant': false,
      'documents': documentUrls,
      'receiverId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // File upload using Supabase
  Future<String> uploadFile(String path) async {
    return await SupabaseService.uploadFile(path);
  }

  // Payment methods
  Future<void> recordDonation({
    required double amount,
    required String requestId,
    required String method,
    required String userId,
  }) async {
    // Record donation
    await _firestore.collection('donations').add({
      'amount': amount,
      'requestId': requestId,
      'method': method,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update request current amount
    DocumentReference requestRef = _firestore.collection('donation_requests').doc(requestId);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(requestRef);
      double currentAmount = snapshot.get('currentAmount') ?? 0.0;
      transaction.update(requestRef, {'currentAmount': currentAmount + amount});
    });
  }

  // Admin methods
  Future<QuerySnapshot> getRequestsByStatus(String status) async {
    return await _firestore
        .collection('donation_requests')
        .where('status', isEqualTo: status)
        .get();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore
        .collection('donation_requests')
        .doc(requestId)
        .update({'status': status});
  }

  Future<void> markRequestAsImportant(String requestId, bool isImportant) async {
    await _firestore
        .collection('donation_requests')
        .doc(requestId)
        .update({'isImportant': isImportant});
  }

  // New methods for donation statistics
  Future<QuerySnapshot> getDonationsSince(DateTime date) async {
    return await _firestore
        .collection('donations')
        .where('createdAt', isGreaterThanOrEqualTo: date)
        .get();
  }

  Future<QuerySnapshot> getTotalDonations() async {
    return await _firestore.collection('donations').get();
  }
}