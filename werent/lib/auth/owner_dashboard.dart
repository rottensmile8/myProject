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

  // ── Computed analytics ───────────────────────────────────────────────────────

  int get _totalVehicles => _vehicles.length;

  double get _totalEarnings => _bookings
      .where((b) => b.status == 'confirmed' || b.status == 'completed')
      .fold(0.0, (sum, b) => sum + b.totalPrice);

  int get _activeBookings =>
      _bookings.where((b) => b.status == 'confirmed').length;

  int get _totalCustomers =>
      _bookings.map((b) => b.renterId).toSet().length;

  int get _pendingBookingsCount =>
      _bookings.where((b) => b.status == 'pending').length;

  List<Booking> get _pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: Colors.green.shade700,
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
            colors: [Colors.green.shade700, Colors.green.shade50],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.user.isActive) _buildApprovalPendingBanner(),
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

  Widget _buildApprovalPendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Approval Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                Text(
                  'Your account is being reviewed by the admin. You can list vehicles once approved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            colors: [Colors.white, Colors.green.shade50],
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
                backgroundColor: Colors.green.shade700,
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
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _showAnalyticsModal(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600),
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
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'OWNER',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
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
          return Padding(
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
                        Icons.directions_car,
                        'Total Vehicles',
                        _totalVehicles.toString()),
                    _buildAnalyticsCardSmall(
                        Icons.attach_money,
                        'Total Earnings',
                        'NPR ${_totalEarnings.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAnalyticsCardSmall(
                        Icons.book_online,
                        'Active Bookings',
                        _activeBookings.toString()),
                    _buildAnalyticsCardSmall(
                        Icons.people,
                        'Total Customers',
                        _totalCustomers.toString()),
                  ],
                ),
                const SizedBox(height: 20),
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
              Icon(icon, size: 30, color: Colors.green),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                title,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
          icon: Icons.add_circle,
          title: 'Add Vehicle',
          subtitle: 'List a new vehicle',
          color: Colors.green.shade400,
          logo: Icons.add_circle,
          onTap: () => Navigator.of(context).pushNamed('/owner/add-vehicle', arguments: widget.user),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.search,
          title: 'Browse Vehicles',
          subtitle: 'View listed vehicles',
          color: Colors.blue.shade400,
          logo: Icons.directions_car,
          onTap: () => Navigator.of(context).pushNamed('/owner/my-vehicles', arguments: widget.user),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.book_online,
          title: 'Bookings',
          subtitle: 'View rental bookings',
          color: Colors.orange.shade400,
          logo: Icons.book_online,
          onTap: () => Navigator.of(context).pushNamed('/owner/bookings', arguments: widget.user),
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
            badgeCount: _pendingBookingsCount,
            onTap: () => _showNotificationsModal(context),
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
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: color),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount pending',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey.shade400,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final pending = _pendingBookings;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (pending.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '${pending.length} New',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: pending.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No pending approvals',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: pending.length,
                          itemBuilder: (context, index) {
                            final booking = pending[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.grey.shade100),
                              ),
                              elevation: 0,
                              color: Colors.grey.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.pending_actions,
                                              color: Colors.orange.shade700),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking.vehicleName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              Text(
                                                'Requested by ${booking.renterName}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                              ),
                                              Text(
                                                booking.renterEmail,
                                                style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Booking ID: ${booking.id.substring(0, 8)}',
                                                style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(height: 1),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          booking.dateRangeDisplay,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'NPR ${booking.totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              final success = await _bookingController
                                                  .updateBookingStatus(
                                                      booking.id, 'cancelled');
                                              if (success) {
                                                await _loadAnalytics();
                                                if (context.mounted) {
                                                  setModalState(() {});
                                                }
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                  color: Colors.red),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('Reject'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final success = await _bookingController
                                                  .updateBookingStatus(
                                                      booking.id, 'confirmed');
                                              if (success) {
                                                await _loadAnalytics();
                                                if (context.mounted) {
                                                  setModalState(() {});
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}