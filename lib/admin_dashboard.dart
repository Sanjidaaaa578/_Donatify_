import 'package:donatify_updated/app_auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  final List<String> _categories = [
    'Health',
    'Education',
    'Environment',
    'Animal Welfare',
    'Orphanage',
    'Calamity Relief'
  ];
  
  Map<String, int> donationStats = {
    'today': 0,
    'week': 0,
    'month': 0,
    'total': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchDonationStats();
  }

  Future<void> _fetchDonationStats() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday));
    final startOfMonth = DateTime(today.year, today.month, 1);

    final todayQuery = await _firebaseService.getDonationsSince(startOfToday);
    final weekQuery = await _firebaseService.getDonationsSince(startOfWeek);
    final monthQuery = await _firebaseService.getDonationsSince(startOfMonth);
    final totalQuery = await _firebaseService.getTotalDonations();

    setState(() {
      donationStats = {
        'today': todayQuery.size,
        'week': weekQuery.size,
        'month': monthQuery.size,
        'total': totalQuery.size,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Provider.of<AppAuthProvider>(context, listen: false).signOut();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildDonationStatsCard(donationStats),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSectorView('Pending'),
                  _buildSectorView('Approved'),
                  _buildSectorView('Rejected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationStatsCard(Map<String, int> stats) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donation Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Today', stats['today']!.toString(), Icons.today),
                _buildStatItem('This Week', stats['week']!.toString(), Icons.calendar_view_week),
                _buildStatItem('This Month', stats['month']!.toString(), Icons.calendar_month),
                _buildStatItem('Total Donations', stats['total']!.toString(), Iconsax.chart_square),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [IconData? icon, String? currencySymbol]) {
    return Column(
      children: [
        if (icon != null) Icon(icon, size: 30, color: Colors.teal),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currencySymbol != null)
              Text(
                currencySymbol,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSectorView(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donation_requests')
          .where('status', isEqualTo: status.toLowerCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $status requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        // Group requests by category
        final Map<String, List<QueryDocumentSnapshot>> requestsByCategory = {};
        for (final request in snapshot.data!.docs) {
          final category = request['category'] as String;
          requestsByCategory.putIfAbsent(category, () => []).add(request);
        }

        // Ensure all categories are represented, even if empty
        for (final category in _categories) {
          requestsByCategory.putIfAbsent(category, () => []);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 200,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final categoryRequests = requestsByCategory[category] ?? [];
            final count = categoryRequests.length;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (categoryRequests.isNotEmpty) {
                    _showCategoryRequests(context, category, categoryRequests, status);
                  }
                },
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
                      const SizedBox(height: 8),
                      Text(
                        '$count ${status.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (index * 100).ms);
          },
        );
      },
    );
  }

  void _showCategoryRequests(BuildContext context, String category, 
      List<QueryDocumentSnapshot> requests, String status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Text(
              '$category ($status)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AdminRequestCard(
                      request: requests[index],
                      status: status,
                    ),
                  );
                },
              ),
            ),
          ],
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
        return Icons.category;
    }
  }
}

class _AdminRequestCard extends StatelessWidget {
  final QueryDocumentSnapshot request;
  final String status;

  const _AdminRequestCard({
    required this.request,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = {
      'Pending': Colors.orange,
      'Approved': Colors.green,
      'Rejected': Colors.red,
    }[status];

    final data = request.data() as Map<String, dynamic>;
    final isImportant = data['isImportant'] as bool? ?? false;
    final title = data['title'] as String? ?? 'No Title';
    final category = data['category'] as String? ?? 'No Category';
    final targetAmount = (data['targetAmount'] as num?)?.toDouble() ?? 0.0;
    final currentAmount = (data['currentAmount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final receiverId = data['receiverId'] as String? ?? 'Unknown';
    final description = data['description'] as String? ?? 'No description';
    final documents = data['documents'] as List<dynamic>? ?? [];

    return Card(
      elevation: isImportant ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isImportant ? Colors.yellow[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isImportant)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'IMPORTANT',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Category: $category'),
            const SizedBox(height: 8),
            Text('Description: $description'),
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(receiverId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Requested by: Loading...');
                }
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return Text('Requested by: Unknown');
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['name'] as String? ?? 'Unknown';
                return Text('Requested by: $userName');
              },
            ),
            const SizedBox(height: 8),
            Text('Target Amount: ৳${targetAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: targetAmount > 0 ? currentAmount / targetAmount : 0,
              backgroundColor: Colors.grey[200],
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Raised: ৳${currentAmount.toStringAsFixed(2)} (${(targetAmount > 0 ? (currentAmount / targetAmount * 100) : 0).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (documents.isNotEmpty) ...[
              const Text(
                'Attached Documents:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: documents.map((doc) {
                  return InkWell(
                    onTap: () => _viewDocument(context, doc),
                    child: Chip(
                      label: Text('Document ${documents.indexOf(doc) + 1}'),
                      deleteIcon: const Icon(Icons.open_in_new, size: 18),
                      onDeleted: () => _viewDocument(context, doc),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            Text('Submitted: $daysAgo days ago'),
            const SizedBox(height: 12),
            if (status == 'Pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDecisionDialog(context, 'Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                      child: const Text('APPROVE', style: TextStyle(fontSize: 8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _markAsImportant(context, !isImportant),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber),
                      ),
                      child: Text(isImportant ? 'UNMARK' : 'IMPORTANT', style: const TextStyle(fontSize: 7)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDecisionDialog(context, 'Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('REJECT', style: TextStyle(fontSize: 8)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDecisionDialog(BuildContext context, String decision) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$decision Request?'),
        content: Text('Are you sure you want to $decision this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final firebaseService = FirebaseService();
              firebaseService.updateRequestStatus(request.id, decision.toLowerCase());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request $decision successfully'),
                  backgroundColor: decision == 'Approved'
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
            child: Text(decision.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _markAsImportant(BuildContext context, bool isImportant) {
    final firebaseService = FirebaseService();
    firebaseService.markRequestAsImportant(request.id, isImportant);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isImportant 
            ? 'Request marked as important'
            : 'Request unmarked as important'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  // In admin_dashboard.dart - Update the _viewDocument method in the _AdminRequestCard class
// In admin_dashboard.dart - Update the _viewDocument method in the _AdminRequestCard class
void _viewDocument(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Document'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(
                  'Failed to load document',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'URL: ${url.length > 30 ? '${url.substring(0, 30)}...' : url}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
      ],
    ),
  );
}}