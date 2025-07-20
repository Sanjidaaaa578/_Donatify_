import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role',style: TextStyle(color:Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'WELCOME!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
            const SizedBox(height: 40),
            _buildRoleCard(
              context,
              icon: Icons.monetization_on,
              title: 'Donor',
              description: 'Support causes by making donations',
              color: Colors.teal,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/login',
                  arguments: 'Donor',
                );
              },
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.5),
            const SizedBox(height: 20),
            _buildRoleCard(
              context,
              icon: Icons.handshake,
              title: 'Receiver',
              description: 'Request donations for your cause',
              color: Colors.amber,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/login',
                  arguments: 'Receiver',
                );
              },
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.5),
            const SizedBox(height: 20),
            _buildRoleCard(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Admin',
              description: 'Manage donation requests',
              color: Colors.indigo,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/login',
                  arguments: 'Admin',
                );
              },
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}