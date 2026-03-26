import 'package:flutter/material.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/models/booking_model.dart';
import 'package:werent/controllers/auth_controller.dart';
import 'package:werent/controllers/booking_controller.dart';
import 'package:werent/auth/browse_vehicles.dart';

class RenterDashboardPage extends StatefulWidget {
  final User user;
  final AuthController authController;

  const RenterDashboardPage({
    super.key,
    required this.user,
    required this.authController,
  });

  @override
  State<RenterDashboardPage> createState() => _RenterDashboardPageState();
}

class _RenterDashboardPageState extends State<RenterDashboardPage> {
  final BookingController _bookingController = BookingController();

  List<Booking> _bookings = [];
  bool _analyticsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);
    final bookings = await _bookingController.getRenterBookings(widget.user.id);
    if (mounted) {
      setState(() {
        _bookings = bookings;
        _analyticsLoading = false;
      });
    }
  }

  // ── Computed analytics ──────────────────────────────────────────────────────

  int get _totalBookings => _bookings.length;

  double get _totalSpent => _bookings
      .where((b) => b.status == 'confirmed' || b.status == 'completed')
      .fold(0.0, (sum, b) => sum + b.totalPrice);

  int get _savedVehiclesCount => globalSavedVehicles.length;

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renter Dashboard'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmLogout == true) {
                await widget.authController.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/auth');
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade50],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context),
                const SizedBox(height: 24),
                _buildQuickActionsSection(context),
                const SizedBox(height: 24),
                _buildAdditionalMenuSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showAnalyticsModal(context),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade700,
                child: Text(
                  widget.user.fullName.isNotEmpty
                      ? widget.user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showAnalyticsModal(context),
              child: const SizedBox(width: 16),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showAnalyticsModal(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      widget.user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'RENTER',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalyticsModal(BuildContext context) {
    // Refresh data every time the modal is opened
    _loadAnalytics();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (_analyticsLoading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Analytics',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        await _loadAnalytics();
                        if (context.mounted) setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildAnalyticsCardSmall(
                      Icons.check_circle,
                      'Total Bookings',
                      _totalBookings.toString(),
                    ),
                    _buildAnalyticsCardSmall(
                      Icons.attach_money,
                      'Total Spent',
                      'NPR ${_totalSpent.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAnalyticsCardSmall(
                      Icons.favorite,
                      'Saved Vehicles',
                      _savedVehiclesCount.toString(),
                    ),
                    _buildAnalyticsCardSmall(
                      Icons.pending_actions,
                      'Pending',
                      _bookings
                          .where((b) => b.status == 'pending')
                          .length
                          .toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCardSmall(IconData icon, String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        _buildActionCard(
          icon: Icons.search,
          title: 'Browse Vehicles',
          subtitle: 'Find your perfect vehicle',
          color: Colors.orange.shade400,
          logo: Icons.directions_car,
          onTap: () =>
              Navigator.of(context).pushNamed('/browse-vehicles', arguments: widget.user),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.history,
          title: 'Rental History',
          subtitle: 'View past rentals',
          color: Colors.purple.shade400,
          logo: Icons.history,
          onTap: () =>
              Navigator.of(context).pushNamed('/renter/rental-history', arguments: widget.user),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.favorite,
          title: 'Saved Vehicles',
          subtitle: 'Your favorite vehicles',
          color: Colors.red.shade400,
          logo: Icons.favorite,
          onTap: () =>
              Navigator.of(context).pushNamed('/renter/saved-vehicles', arguments: widget.user),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.support_agent,
          title: 'Support',
          subtitle: 'Get help & assistance',
          color: Colors.teal.shade400,
          logo: Icons.support_agent,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required IconData logo,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(logo, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalMenuSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            color: Colors.grey.shade600,
            onTap: () {},
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            color: Colors.grey.shade600,
            onTap: () {},
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            color: Colors.grey.shade600,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}
