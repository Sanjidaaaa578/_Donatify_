// payment_screen.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'app_auth_provider.dart';
import 'firebase_service.dart';

class PaymentScreen extends StatefulWidget {
  final String requestId;
  const PaymentScreen({super.key, required this.requestId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'Bkash';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Donation', style: TextStyle(color: Colors.black)),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Donation Amount',
                style: TextStyle(fontSize: 18),
              )
              .animate()
              .fadeIn(delay: 200.ms),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              )
              .animate()
              .fadeIn(delay: 300.ms),
              
              const SizedBox(height: 30),
                
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18),
              )
              .animate()
              .fadeIn(delay: 400.ms),
              
              const SizedBox(height: 16),
              
              _PaymentMethodCard(
                icon: Icons.mobile_friendly,
                title: 'Bkash',
                isSelected: _selectedMethod == 'Bkash',
                onTap: () => setState(() => _selectedMethod = 'Bkash'),
              )
              .animate()
              .fadeIn(delay: 500.ms)
              .slideX(begin: -0.2),
              
              const SizedBox(height: 16),
              
              _PaymentMethodCard(
                icon: Icons.phone_android,
                title: 'Nagad',
                isSelected: _selectedMethod == 'Nagad',
                onTap: () => setState(() => _selectedMethod = 'Nagad'),
              )
              .animate()
              .fadeIn(delay: 600.ms)
              .slideX(begin: 0.2),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _processPayment(context),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('PROCEED TO PAYMENT'),
                ),
              )
              .animate()
              .fadeIn(delay: 700.ms)
              .slideY(begin: 0.5),
              
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0 
                    ? MediaQuery.of(context).viewInsets.bottom + 20 
                    : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final auth = Provider.of<AppAuthProvider>(context, listen: false);
      final userId = auth.currentUser!.uid;
      final amount = double.parse(_amountController.text);
      
      final firebaseService = FirebaseService();
      await firebaseService.recordDonation(
        amount: amount,
        requestId: widget.requestId,
        method: _selectedMethod,
        userId: userId,
      );
      
      _showSuccessDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Donation Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for donating ৳${_amountController.text}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Updated to go back to donor dashboard instead of login
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/donor-dashboard',
                      (route) => false,
                    );
                  },
                  child: const Text('BACK TO DASHBOARD'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
            ? Theme.of(context).primaryColor
            : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}