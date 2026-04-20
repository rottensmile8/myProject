import 'package:flutter/material.dart';
import 'package:werent/models/booking_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/booking_controller.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:werent/models/vehicle_model.dart';

class RentalHistoryScreen extends StatefulWidget {
  final User user;

  const RentalHistoryScreen({super.key, required this.user});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  final BookingController _bookingController = BookingController();
  List<Booking> _bookings = [];
  bool _isLoading = true;

  // Consistent Theme Palette
  static const Color primaryOrange = Color(0xFFFF8A00);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color softOrangeBg = Color(0xFFFFF5E9);
  static const Color darkText = Color(0xFF3E2723);
  static const Color lightText = Color(0xFF8D6E63);

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings =
          await _bookingController.getRenterBookings(widget.user.id);
      setState(() => _bookings = bookings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Rental History',
            style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded, color: primaryOrange),
              onPressed: _loadBookings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : _bookings.isEmpty
              ? _buildEmptyState()
              : _buildBookingList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 80, color: softOrangeBg),
          const SizedBox(height: 16),
          const Text('No history found',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 8),
          const Text('Your past trips will appear here',
              style: TextStyle(color: lightText)),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    final confirmed = _bookings.where((b) => b.status == 'confirmed').toList();
    final pending = _bookings.where((b) => b.status == 'pending').toList();
    final completed = _bookings.where((b) => b.status == 'completed').toList();
    final cancelled = _bookings.where((b) => b.status == 'cancelled').toList();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: primaryOrange,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          if (confirmed.isNotEmpty) ...[
            _buildSectionHeader('Confirmed', confirmed.length, Colors.green),
            ...confirmed.map(_buildBookingCard)
          ],
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('Pending', pending.length, primaryOrange),
            ...pending.map(_buildBookingCard)
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('Completed', completed.length, Colors.blue),
            ...completed.map(_buildBookingCard)
          ],
          if (cancelled.isNotEmpty) ...[
            _buildSectionHeader('Cancelled', cancelled.length, Colors.red),
            ...cancelled.map(_buildBookingCard)
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final imageBytes =
        Vehicle.safeDecodeImage(booking.vehicleImageBase64 ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header with Tinted Background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: softOrangeBg.withOpacity(0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryOrange.withOpacity(0.2)),
                    image: imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(imageBytes), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imageBytes == null
                      ? Icon(
                          booking.vehicleCategory == 'bike'
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          color: primaryOrange)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.vehicleName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkText)),
                      Text(
                          'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                          style:
                              const TextStyle(fontSize: 11, color: lightText)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(booking.statusDisplay,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ],
            ),
          ),

          // Visible Info Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Info Details with Clear Border
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: primaryOrange.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 16, color: primaryOrange),
                          const SizedBox(width: 8),
                          Text(booking.dateRangeDisplay,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: darkText,
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('${booking.rentalDays} days',
                              style: const TextStyle(
                                  fontSize: 12, color: lightText)),
                        ],
                      ),
                      if (booking.isCurrentlyRented) ...[
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('${booking.daysRemaining} days left',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Price Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: softOrangeBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: darkText)),
                      Text('NPR ${booking.totalPrice.toInt()}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryOrange)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (booking.status == 'confirmed' && !booking.isCurrentlyRented)
                  _buildActionBtn(Icons.cancel_outlined, 'Cancel', Colors.red,
                      () => _showCancelDialog(booking)),
                if (booking.status == 'confirmed' && booking.isCurrentlyRented)
                  _buildActionBtn(Icons.assignment_return_outlined, 'Return',
                      Colors.green, () => _showReturnDialog(booking)),
                if (booking.status == 'completed' ||
                    booking.status == 'cancelled')
                  _buildActionBtn(Icons.delete_outline_rounded, 'Delete',
                      lightText, () => _confirmDelete(booking)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  // Dialog Methods
  Future<void> _showCancelDialog(Booking booking) async {
    final now = DateTime.now();
    final isWithin24h =
        now.isAfter(booking.endDate.subtract(const Duration(hours: 24)));
    final refund = isWithin24h ? booking.totalPrice * 0.9 : booking.totalPrice;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Trip?'),
        content: Text(
            'Refund: NPR ${refund.toInt()}\n(${isWithin24h ? "90%" : "100%"} policy)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (res == true) _updateStatus(booking, 'cancelled', refund);
  }

  Future<void> _showReturnDialog(Booking booking) async {
  // Logic: Charge for today, refund only for the days AFTER today.
  // If 4 days left, we refund 3.
  int refundableDays = (booking.daysRemaining - 1).clamp(0, booking.rentalDays);
  
  final refund = (refundableDays / booking.rentalDays) * booking.totalPrice;

  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Return Vehicle?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You are returning this today.'),
          const SizedBox(height: 8),
          Text('Remaining days: ${booking.daysRemaining}'),
          Text('Refundable days: $refundableDays', 
               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const Divider(),
          Text('Refund Amount: NPR ${refund.toInt()}',
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Rental')),
        ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Return', style: TextStyle(color: Colors.white))),
      ],
    ),
  );

  if (res == true) _updateStatus(booking, 'completed', refund);
}

  Future<void> _updateStatus(
    Booking booking, String status, double refund) async {
  
  // Call the controller with the refund amount
  final success = await _bookingController
      .updateBookingStatus(booking.id, status, refundAmount: refund);
  
  if (success && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Update successful! Refund: NPR ${refund.toInt()}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating),
    );
    _loadBookings(); // Refresh the list
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Failed to update status. Please try again.'),
          backgroundColor: Colors.red),
    );
  }
}

  Future<void> _confirmDelete(Booking booking) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Remove from history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (res == true) {
      final success = await _bookingController.deleteBooking(booking.id);
      if (success && mounted) _loadBookings();
    }
  }
}
