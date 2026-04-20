import 'package:flutter/material.dart';
import 'package:werent/models/booking_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/booking_controller.dart';
import 'dart:convert';
import 'dart:typed_data';

class BookingsScreen extends StatefulWidget {
  final User user;
  const BookingsScreen({super.key, required this.user});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingController _bookingController = BookingController();
  List<Booking> _bookings = [];
  bool _isLoading = true;

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
          await _bookingController.getOwnerBookings(widget.user.id);
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
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'in rent':
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
        title: const Text('Bookings',
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

  Widget _buildBookingList() {
    final confirmed = _bookings
        .where((b) =>
            b.status.toLowerCase() == 'confirmed' ||
            b.status.toLowerCase() == 'in rent')
        .toList();
    final completed =
        _bookings.where((b) => b.status.toLowerCase() == 'completed').toList();
    final cancelled =
        _bookings.where((b) => b.status.toLowerCase() == 'cancelled').toList();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: primaryOrange,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          if (confirmed.isNotEmpty) ...[
            _buildSectionHeader('In Rent', confirmed.length, Colors.green),
            ...confirmed.map(_buildBookingCard)
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
    final imageBytes = _decodeBase64Image(booking.vehicleImageBase64 ?? '');

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: softOrangeBg,
                    borderRadius: BorderRadius.circular(12),
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
                              fontWeight: FontWeight.bold,
                              color: darkText,
                              fontSize: 16)),
                      Text("ID: #${booking.id.substring(0, 6).toUpperCase()}",
                          style:
                              const TextStyle(fontSize: 11, color: lightText)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_outline, booking.renterName),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_month_outlined,
                    "${booking.dateRangeDisplay} (${booking.rentalDays} days)"),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Earnings",
                          style: TextStyle(color: lightText, fontSize: 13)),
                      Text("NPR ${booking.totalPrice.toInt()}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Delete for Completed/Cancelled
          if (booking.status.toLowerCase() == 'completed' ||
              booking.status.toLowerCase() == 'cancelled')
            Container(
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF5F5F5)))),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(booking),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  label: const Text("Delete Record",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryOrange),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: lightText, fontSize: 13))),
      ],
    );
  }

  Uint8List? _decodeBase64Image(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      String cleanBase64 = base64;
      if (base64.contains(',')) {
        final parts = base64.split(',');
        cleanBase64 = parts.length > 1 ? parts[1] : base64;
      }
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Base64 decode error: $e');
      return null;
    }
  }

  Future<void> _confirmDelete(Booking booking) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Remove this from history?'),
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
      if (success && mounted) {
        _loadBookings();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Record deleted')));
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_online_outlined, size: 80, color: softOrangeBg),
          const SizedBox(height: 16),
          const Text('No bookings yet',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
        ],
      ),
    );
  }
}
