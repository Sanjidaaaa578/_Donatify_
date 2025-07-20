import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'app_auth_provider.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';

class ReceiverDonationForm extends StatefulWidget {
  const ReceiverDonationForm({super.key});

  @override
  State<ReceiverDonationForm> createState() => _ReceiverDonationFormState();
}

class _ReceiverDonationFormState extends State<ReceiverDonationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  final _categories = [
    'Health',
    'Education',
    'Environment',
    'Animal Welfare',
    'Orphanage',
    'Calamity Relief'
  ];
  List<File> _attachedDocuments = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _attachDocument() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() => _isUploading = true);
        _attachedDocuments.add(File(pickedFile.path));
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to attach document: ${e.toString()}')),
      );
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _attachedDocuments.removeAt(index);
    });
  }

  Future<List<String>> _uploadDocuments() async {
    List<String> urls = [];
    for (File file in _attachedDocuments) {
      String url = await SupabaseService.uploadFile(file.path);
      urls.add(url);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Donation Request', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Request Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedCategory,
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount (BDT)',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an amount' : null,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Detailed Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 5,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 20),
              
              const Text(
                'Required Documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Attach supporting documents (NID, Organization proof, etc.)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              if (_isUploading)
                const LinearProgressIndicator()
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach Document'),
                  onPressed: _attachDocument,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              if (_attachedDocuments.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attached Documents:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attachedDocuments.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(
                            'Document ${index + 1}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeDocument(index),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _attachedDocuments.isEmpty || _isUploading
                      ? null
                      : _submitForm,
                  child: const Text('SUBMIT REQUEST'),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      
      try {
        // Upload documents to Supabase
        List<String> documentUrls = await _uploadDocuments();
        
        // Get the current user id
        final auth = Provider.of<AppAuthProvider>(context, listen: false);
        String userId = auth.currentUser!.uid;
        
        // Create donation request in Firestore
        final firebaseService = FirebaseService();
        await firebaseService.createDonationRequest(
          title: _titleController.text,
          category: _selectedCategory!,
          amount: double.parse(_amountController.text),
          description: _descriptionController.text,
          documentUrls: documentUrls,
          userId: userId,
        );
        
        setState(() => _isUploading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Submitted'),
            content: const Text(
                'Your donation request has been sent for admin approval'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to receiver dashboard
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    }
  }
}