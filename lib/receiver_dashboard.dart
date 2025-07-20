import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_auth_provider.dart';

class ReceiverDashboard extends StatefulWidget {
  const ReceiverDashboard({super.key});

  @override
  State<ReceiverDashboard> createState() => _ReceiverDashboardState();
}

class _ReceiverDashboardState extends State<ReceiverDashboard> {
  late String _userId;
  late int _approvedCount;
  late int _pendingCount;
  late int _rejectedCount;
  late double _totalAmount;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    _userId = auth.currentUser!.uid;
    _approvedCount = 0;
    _pendingCount = 0;
    _rejectedCount = 0;
    _totalAmount = 0.0;
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final requests = await FirebaseFirestore.instance
        .collection('donation_requests')
        .where('receiverId', isEqualTo: _userId)
        .get();

    int approved = 0;
    int pending = 0;
    int rejected = 0;
    double total = 0.0;

    for (var request in requests.docs) {
      final status = request['status'] as String;
      final amount = request['targetAmount'] as double;

      if (status == 'approved') {
        approved++;
        total += amount;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'rejected') {
        rejected++;
      }
    }

    setState(() {
      _approvedCount = approved;
      _pendingCount = pending;
      _rejectedCount = rejected;
      _totalAmount = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Donation Requests', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/receiver-form');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsCard(context)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2),
            
            const SizedBox(height: 20),
            
            const Text(
              'My Active Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )
            .animate()
            .fadeIn(delay: 300.ms),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('donation_requests')
                    .where('receiverId', isEqualTo: _userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final requests = snapshot.data!.docs;
                  
                  return ListView.separated(
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _RequestCard(request: requests[index])
                        .animate()
                        .fadeIn(delay: (400 + (index * 150)).ms)
                        .slideX(begin: 0.1);
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

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Donation Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Approved', _approvedCount.toString(), Colors.green),
                _buildStatItem('Pending', _pendingCount.toString(), Colors.orange),
                _buildStatItem('Rejected', _rejectedCount.toString(), Colors.red),
                _buildStatItem('Total', '৳${_totalAmount.toStringAsFixed(2)}', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final QueryDocumentSnapshot request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String;
    final statusColor = {
      'approved': Colors.green,
      'pending': Colors.orange,
      'rejected': Colors.red,
    }[status];

    final title = request['title'] as String;
    final targetAmount = request['targetAmount'] as double;
    final currentAmount = request['currentAmount'] as double;
    final progress = currentAmount / targetAmount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.isNaN ? 0 : progress,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Raised: ৳${currentAmount.toStringAsFixed(2)}'),
                Text('Goal: ৳${targetAmount.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}