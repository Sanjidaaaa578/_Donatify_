import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://atxeyuhmpojexhrxeusy.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0eGV5dWhtcG9qZXhocnhldXN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzMTI1OTUsImV4cCI6MjA2Nzg4ODU5NX0.tNzKPAeiIuCk_DW2u-DJTZaZApBufnQRj3NtsJ9HoQI',
    );
  }

  // File Upload to Supabase
  static Future<String> uploadFile(String filePath, {String? fileName}) async {
    try {
      final file = File(filePath);
      final fileExt = filePath.split('.').last;
      final newFileName = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload the file directly
      await _client.storage
          .from('donatify')  // Changed from 'donation.documents' to 'donation_documents'
          .upload(newFileName, file);

      return getPublicUrl(newFileName);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Get public URL
  static String getPublicUrl(String fileName) {
    return _client.storage
        .from('donatify')
        .getPublicUrl(fileName);
  }

  // File Delete
  static Future<void> deleteFile(String fileName) async {
    try {
      await _client.storage
          .from('donatify')
          .remove([fileName]);
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }
}