import 'package:flutter/material.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/models/booking_model.dart';
import 'package:werent/controllers/auth_controller.dart';
import 'package:werent/controllers/booking_controller.dart';
import 'package:werent/auth/browse_vehicles.dart';
import 'package:werent/models/notification_model.dart';
import 'package:werent/controllers/notification_controller.dart';

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
  final NotificationController _notificationController = NotificationController();

  List<Booking> _bookings = [];
  List<NotificationModel> _notifications = [];
  bool _analyticsLoading = true;

  // Consistent Theme Palette
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
      _bookingController.getRenterBookings(widget.user.id),
      _notificationController.getNotifications(widget.user.id),
    ]);
    if (mounted) {
      setState(() {
        _bookings = results[0] as List<Booking>;
        _notifications = results[1] as List<NotificationModel>;
        _analyticsLoading = false;
      });
    }
  }

  int get _totalBookings => _bookings.length;
  double get _totalSpent => _bookings
      .where((b) => b.status == 'confirmed' || b.status == 'completed')
      .fold(0.0, (sum, b) => sum + b.totalPrice);
  bool get hasActiveRental => _bookings.any((b) => b.status == 'confirmed');
  int get _savedVehiclesCount => globalSavedVehicles.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        title: const Text('Renter Dashboard', 
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
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
              const Text("Quick Actions", 
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
          const Icon(Icons.info_outline_rounded, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Account review in progress. Some features may be restricted until approved.',
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
            Text('Hello,', style: TextStyle(color: lightText, fontSize: 14)),
            Text(widget.user.fullName, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
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
            if (_notificationController.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('${_notificationController.unreadCount}', 
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), 
                    textAlign: TextAlign.center),
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
        _buildStatCard("Total Spent", "NPR ${_totalSpent.toInt()}", Icons.account_balance_wallet_outlined),
        const SizedBox(width: 16),
        _buildStatCard("Bookings", "$_totalBookings", Icons.calendar_today_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: softOrangeBg, borderRadius: BorderRadius.circular(20)),
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
          "Browse Vehicles",
          "Find your perfect ride",
          Icons.search_rounded,
          () => Navigator.pushNamed(context, '/browse-vehicles', arguments: widget.user),
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          "Rental History",
          "Past journeys and receipts",
          Icons.history_rounded,
          () => Navigator.pushNamed(context, '/renter/rental-history', arguments: widget.user),
          color: Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          "Saved Vehicles",
          "Your favorite picks",
          Icons.favorite_outline_rounded,
          () => Navigator.pushNamed(context, '/renter/saved-vehicles', arguments: widget.user),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildActionTile(String title, String sub, IconData icon, VoidCallback onTap, {required Color color}) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
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
      decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          _buildSimpleMenuItem("Settings", Icons.settings_outlined, () {}),
          Divider(height: 1, color: Colors.grey.shade200, indent: 50),
          _buildSimpleMenuItem("Privacy Policy", Icons.privacy_tip_outlined, () {}),
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

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: surfaceWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Notifications", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
                if (_notifications.isNotEmpty)
                  TextButton(onPressed: () => _notificationController.clearAllNotifications(widget.user.id), 
                    child: const Text("Clear All", style: TextStyle(color: primaryOrange)))
              ],
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(child: Text("No new notifications", style: TextStyle(color: lightText)))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: softOrangeBg, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(notification.type == 'error' ? Icons.error_outline : Icons.info_outline_rounded, 
               color: notification.type == 'error' ? Colors.red : primaryOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
                Text(notification.message, style: const TextStyle(fontSize: 12, color: lightText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await widget.authController.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  void _showAnalyticsModal(BuildContext context) {
    // Shared modal logic for total bookings, spent, etc.
  }
}