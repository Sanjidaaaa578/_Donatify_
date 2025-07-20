import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationDetailsPage extends StatelessWidget {
  final String category;
  const DonationDetailsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Donations', style: const TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'category-$category',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms),
            
            const SizedBox(height: 20),
            
            const Text(
              'Active Campaigns',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms),
            
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donation_requests')
                  .where('category', isEqualTo: category)
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final requests = snapshot.data!.docs;
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _DonationCampaignCard(
                      index: index,
                      category: category,
                      request: request,
                      onDonate: () {
                        Navigator.pushNamed(
                          context, 
                          '/payment',
                          arguments: request.id,
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: (500 + (index * 200)).ms)
                    .slideX(begin: 0.2);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationCampaignCard extends StatelessWidget {
  final int index;
  final String category;
  final QueryDocumentSnapshot request;
  final VoidCallback onDonate;

  const _DonationCampaignCard({
    required this.index,
    required this.category,
    required this.request,
    required this.onDonate,
  });

  @override
  Widget build(BuildContext context) {
    final isImportant = request['isImportant'] as bool;
    final title = request['title'] as String;
    final description = request['description'] as String;
    final targetAmount = request['targetAmount'] as double;
    final currentAmount = request['currentAmount'] as double;
    final progress = currentAmount / targetAmount;
    final fundedPercentage = (progress * 100).toStringAsFixed(0);

    return Card(
      elevation: isImportant ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isImportant ? Colors.yellow[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isImportant)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ADMIN PRIORITY',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress.isNaN ? 0 : progress,
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$fundedPercentage% funded',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Raised: ৳${currentAmount.toStringAsFixed(2)}'),
                Text('Goal: ৳${targetAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDonate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isImportant 
                      ? Colors.amber 
                      : Theme.of(context).primaryColor,
                ),
                child: Text(
                  'DONATE NOW',
                  style: TextStyle(
                    color: isImportant ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}