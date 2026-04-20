import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/booking_model.dart';
import 'package:werent/controllers/auth_controller.dart';
import 'package:werent/controllers/booking_controller.dart';
import 'package:werent/controllers/vehicle_controller.dart';
import 'package:werent/controllers/notification_controller.dart';

class OwnerDashboardPage extends StatefulWidget {
  final User user;
  final AuthController authController;

  const OwnerDashboardPage({
    super.key,
    required this.user,
    required this.authController,
  });

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  final BookingController _bookingController = BookingController();
  final VehicleController _vehicleController = VehicleController();

  List<Booking> _bookings = [];
  List<Vehicle> _vehicles = [];
  bool _analyticsLoading = true;

  // Standardized Theme Palette (Matching Renter Dashboard)
  static const Color primaryOrange = Color(0xFFFF8A00);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color softOrangeBg = Color(0xFFFFF5E9);
  static const Color darkText = Color(0xFF3E2723);
  static const Color lightText = Color(0xFF8D6E63);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationController>(context, listen: false)
            .getNotifications(widget.user.id);
      }
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);
    try {
      final results = await Future.wait([
        _bookingController.getOwnerBookings(widget.user.id),
        _vehicleController.getOwnerVehicles(widget.user.id),
      ]);
      if (mounted) {
        setState(() {
          _bookings = results[0] as List<Booking>;
          _vehicles = results[1] as List<Vehicle>;
          _analyticsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _analyticsLoading = false);
    }
  }

  double get _totalEarnings => _bookings
      .where((b) => b.status == 'confirmed' || b.status == 'completed')
      .fold(0.0, (sum, b) => sum + b.totalPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        toolbarHeight: 60, 
        title: const Text('Owner Dashboard', 
            style: TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          _buildNotificationIcon(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: primaryOrange),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.user.isActive) _buildApprovalPendingBanner(),
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildStatsGrid(),
              const SizedBox(height: 30),
              const Text("Management", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildMenuCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Ensure these methods ALWAYS return a Widget and never null
  Widget _buildNotificationIcon() {
    return Consumer<NotificationController>(
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () => _showNotificationsModal(context, controller),
          child: Container(
            width: 45,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: softOrangeBg, borderRadius: BorderRadius.circular(12)),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: primaryOrange, size: 24),
                if (controller.unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${controller.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: primaryOrange, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'U', 
                style: const TextStyle(color: primaryOrange, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back,', style: TextStyle(color: lightText, fontSize: 14)),
            Text(widget.user.fullName, 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard("Earnings", "NPR ${_totalEarnings.toInt()}", Icons.account_balance_wallet_outlined),
        const SizedBox(width: 16),
        _buildStatCard("Vehicles", "${_vehicles.length}", Icons.directions_car_outlined),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: softOrangeBg, 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryOrange, size: 28),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
            Text(label, style: const TextStyle(fontSize: 13, color: lightText)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _buildActionTile("Add Vehicle", "List a new ride to start earning", Icons.add_rounded, 
            () => Navigator.pushNamed(context, '/owner/add-vehicle', arguments: widget.user)),
        const SizedBox(height: 12),
        _buildActionTile("My Vehicles", "Manage and edit your listed fleet", Icons.garage_outlined, 
            () => Navigator.pushNamed(context, '/owner/my-vehicles', arguments: widget.user)),
        const SizedBox(height: 12),
        _buildActionTile("Bookings", "View active and past rental history", Icons.calendar_month_outlined, 
            () => Navigator.pushNamed(context, '/owner/bookings', arguments: widget.user)),
      ],
    );
  }

  Widget _buildActionTile(String title, String sub, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: softOrangeBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: primaryOrange, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: lightText)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB), 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildSimpleMenuItem("Settings", Icons.settings_outlined, () {}),
          Divider(height: 1, color: Colors.grey.shade100, indent: 70),
          //_buildSimpleMenuItem("Help Center", Icons.help_outline_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildSimpleMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: darkText, size: 26),
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: darkText)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildApprovalPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.amber.shade200)
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text("Pending admin approval to list vehicles.", 
              style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500))
          ),
        ],
      ),
    );
  }

  void _showNotificationsModal(BuildContext context, NotificationController controller) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          
          // Header Row with Clear All Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Notifications", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
              if (controller.notifications.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    bool success = await controller.clearAllNotifications(widget.user.id);
                    if (success && mounted) {
                      Navigator.pop(context); // Close modal after clearing
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("All notifications cleared"), behavior: SnackBarBehavior.floating)
                      );
                    }
                  },
                  child: const Text("Clear All", 
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          Expanded(
            child: controller.notifications.isEmpty
                ? const Center(child: Text("No notifications yet", style: TextStyle(color: lightText)))
                : ListView.builder(
                    itemCount: controller.notifications.length,
                    itemBuilder: (context, index) {
                      final n = controller.notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softOrangeBg,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: primaryOrange,
                            child: Icon(Icons.notifications_active, color: Colors.white, size: 18),
                          ),
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(n.message),
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
  void _handleLogout() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Logout")),
        ],
      ),
    );
    if (res == true) {
      await widget.authController.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    }
  }
}