import 'package:flutter/material.dart';
import 'package:werent/models/user_model.dart';


class DashboardPage extends StatelessWidget {
  final User user;

  const DashboardPage({super.key, required this.user});
  
  get auth_controller => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth_controller.logout();
              Navigator.pushReplacementNamed(context, '/auth'); // go back to login
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade300,
                      child: Text(
                        user.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Action Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.directions_car,
                    title: 'My Cars',
                    color: Colors.orange.shade400,
                    onTap: () {
                      // Navigate to owner's car page
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.book_online,
                    title: 'My Bookings',
                    color: Colors.green.shade400,
                    onTap: () {
                      // Navigate to bookings page
                    },
                  ),
                  // _buildActionCard(
                  //   icon: Icons.settings,
                  //   title: 'Settings',
                  //   color: Colors.purple.shade400,
                  //   onTap: () {
                  //     // Navigate to settings page
                  //   },
                  // ),
                  _buildActionCard(
                    icon: Icons.help_outline,
                    title: 'Support',
                    color: Colors.blue.shade400,
                    onTap: () {
                      // Navigate to support page
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for creating action cards
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withBlue(600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
