import 'package:flutter/material.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/booking_model.dart';
import 'package:werent/controllers/auth_controller.dart';
import 'package:werent/controllers/booking_controller.dart';
import 'package:werent/controllers/vehicle_controller.dart';

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

  // Theme Colors
  static const Color primaryOrange = Color(0xFFFF8A00);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color softOrangeBg = Color(0xFFFFF5E9);
  static const Color darkText = Color(0xFF3E2723);
  static const Color lightText = Color(0xFF8D6E63);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);
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
  }

  // analytics
  int get _totalVehicles => _vehicles.length;
  double get _totalEarnings => _bookings
      .where((b) => b.status == 'confirmed' || b.status == 'completed')
      .fold(0.0, (sum, b) => sum + b.totalPrice);
  int get _activeBookings => _bookings.where((b) => b.status == 'confirmed').length;
  int get _totalCustomers => _bookings.map((b) => b.renterId).toSet().length;
  int get _pendingBookingsCount => _bookings.where((b) => b.status == 'pending').length;
  List<Booking> get _pendingBookings => _bookings.where((b) => b.status == 'pending').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        title: const Text('Dashboard', style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: primaryOrange),
            onPressed: _handleLogout,
          ),
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
               _buildProfileHeader(context),
               const SizedBox(height: 30),
                _buildStatsGrid(),
                const SizedBox(height: 30),
                //const Text("Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
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

  Widget _buildApprovalPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.privacy_tip_outlined, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Account review in progress. You can manage your vehicles once approved by the Admin.',
              style: TextStyle(fontSize: 13, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showAnalyticsModal(context),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: primaryOrange, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                widget.user.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 24, color: primaryOrange, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(color: lightText, fontSize: 14)),
            Text(widget.user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
          ],
        ),
        const Spacer(),
        _buildNotificationIcon(),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () => _showNotificationsModal(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: softOrangeBg, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, color: primaryOrange),
            if (_pendingBookingsCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$_pendingBookingsCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard("Earnings", "NPR ${_totalEarnings.toInt()}", Icons.account_balance_wallet_outlined),
        const SizedBox(width: 16),
        _buildStatCard("Vehicles", "$_totalVehicles", Icons.directions_car_outlined),
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
        _buildActionTile(
          "Add Vehicle",
          "List a new ride",
          Icons.add_rounded,
          () => Navigator.pushNamed(context, '/owner/add-vehicle', arguments: widget.user),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          "My Vehicles",
          "Manage listed vehicles",
          Icons.garage_outlined,
          () => Navigator.pushNamed(context, '/owner/my-vehicles', arguments: widget.user),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          "Bookings",
          "Check rental status",
          Icons.calendar_month_outlined,
          () => Navigator.pushNamed(context, '/owner/bookings', arguments: widget.user),
        ),
      ],
    );
  }

  Widget _buildActionTile(String title, String sub, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: softOrangeBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: primaryOrange),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
                Text(sub, style: const TextStyle(fontSize: 12, color: lightText)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _buildSimpleMenuItem("Settings", Icons.settings_outlined, () {}),
          Divider(height: 1, color: Colors.grey.shade200, indent: 50),
          _buildSimpleMenuItem("Help Center", Icons.help_outline_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildSimpleMenuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: darkText, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: darkText)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
      onTap: onTap,
    );
  }

  // Same logic as before but with the new Orange/White Modal theme
  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("Pending Requests", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 20),
            Expanded(
              child: _pendingBookings.isEmpty 
                ? const Center(child: Text("No new requests", style: TextStyle(color: lightText)))
                : ListView.builder(
                    itemCount: _pendingBookings.length,
                    itemBuilder: (context, i) => _buildRequestCard(_pendingBookings[i]),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softOrangeBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions_rounded, color: primaryOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
                    Text("By ${booking.renterName}", style: const TextStyle(fontSize: 12, color: lightText)),
                  ],
                ),
              ),
              Text("NPR ${booking.totalPrice.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _updateStatus(booking.id, 'cancelled'),
                  child: const Text("Reject", style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(booking.id, 'confirmed'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, elevation: 0),
                  child: const Text("Approve", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    final success = await _bookingController.updateBookingStatus(id, status);
    if (success) {
      _loadAnalytics();
      Navigator.pop(context);
    }
  }

  void _handleLogout() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Finish your session?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Stay")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await widget.authController.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  // Placeholder for the chart/analytics modal
  void _showAnalyticsModal(BuildContext context) {
    _loadAnalytics();
    // Implementation of stats breakdown...
  }
}