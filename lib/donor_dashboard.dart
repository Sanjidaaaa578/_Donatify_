// donor_dashboard.dart (updated)
import 'package:donatify_updated/app_auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Health',
      'Education',
      'Environment',
      'Animal Welfare',
      'Orphanage',
      'Calamity Relief'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate to Causes', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showDonationHistory(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select a category to donate',
              style: TextStyle(fontSize: 18),
            )
            .animate()
            .fadeIn(delay: 200.ms),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _CategoryCard(
                    category: categories[index],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/donation-details',
                        arguments: categories[index],
                      );
                    },
                  )
                  .animate()
                  .fadeIn(delay: (300 + (index * 100)).ms)
                  .slideY(begin: 0.2);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDonationHistory(BuildContext context) {
    final userId = Provider.of<AppAuthProvider>(context, listen: false).currentUser!.uid;
    final dateFormat = DateFormat('dd MMM yyyy');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Text(
              'Your Donation History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('donations')
                    .where('userId', isEqualTo: userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 50, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading donations: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 50, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No donation history yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your donations will appear here',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final donations = snapshot.data!.docs;
                  
                  return ListView.separated(
                    itemCount: donations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final donation = donations[index];
                      final amount = donation['amount'] as double;
                      final date = (donation['createdAt'] as Timestamp).toDate();
                      final formattedDate = dateFormat.format(date);
                      final method = donation['method'] as String;
                      final requestId = donation['requestId'] as String;
                      
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('donation_requests')
                            .doc(requestId)
                            .get(),
                        builder: (context, campaignSnapshot) {
                          if (campaignSnapshot.connectionState == ConnectionState.waiting) {
                            return _buildLoadingDonationItem(amount, formattedDate, method);
                          }
                          
                          if (!campaignSnapshot.hasData || !campaignSnapshot.data!.exists) {
                            return _buildUnknownCampaignItem(amount, formattedDate, method);
                          }
                          
                          final campaign = campaignSnapshot.data!;
                          final campaignTitle = campaign['title'] as String;
                          final campaignCategory = campaign['category'] as String;
                          final campaignStatus = campaign['status'] as String? ?? 'unknown';
                          
                          return _buildDonationItem(
                            context,
                            amount: amount,
                            date: formattedDate,
                            method: method,
                            title: campaignTitle,
                            category: campaignCategory,
                            status: campaignStatus,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDonationItem(double amount, String date, String method) {
    return ListTile(
      leading: const CircularProgressIndicator(),
      title: Text('৳${amount.toStringAsFixed(2)}'),
      subtitle: Text('$date • $method'),
    );
  }

  Widget _buildUnknownCampaignItem(double amount, String date, String method) {
    return ListTile(
      leading: const Icon(Icons.monetization_on, color: Colors.grey),
      title: Text('৳${amount.toStringAsFixed(2)}'),
      subtitle: Text('$date • $method'),
      trailing: const Text('Campaign not found', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildDonationItem(
    BuildContext context, {
    required double amount,
    required String date,
    required String method,
    required String title,
    required String category,
    required String status,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getIconForCategory(category),
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$date • $category'),
          Text(
            'Paid via $method',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '৳${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: status == 'approved'
                  ? Colors.green
                  : status == 'pending'
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Health':
        return Icons.medical_services;
      case 'Education':
        return Icons.school;
      case 'Environment':
        return Icons.eco;
      case 'Animal Welfare':
        return Icons.pets;
      case 'Orphanage':
        return Icons.family_restroom;
      case 'Calamity Relief':
        return Icons.emergency;
      default:
        return Icons.help;
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForCategory(category),
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 10),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Health':
        return Icons.medical_services;
      case 'Education':
        return Icons.school;
      case 'Environment':
        return Icons.eco;
      case 'Animal Welfare':
        return Icons.pets;
      case 'Orphanage':
        return Icons.family_restroom;
      case 'Calamity Relief':
        return Icons.emergency;
      default:
        return Icons.help;
    }
  }
}