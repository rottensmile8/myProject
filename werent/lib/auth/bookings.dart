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

  // Theme Palette
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
          const SizedBox(height: 8),
          const Text('Rental requests will appear here',
              style: TextStyle(color: lightText)),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    // final pending = _bookings.where((b) => b.status == 'pending').toList();
    final confirmed = _bookings.where((b) => b.status == 'In Rent').toList();
    final completed = _bookings.where((b) => b.status == 'completed').toList();
    final cancelled = _bookings.where((b) => b.status == 'cancelled').toList();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: primaryOrange,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // if (pending.isNotEmpty) ...[_buildSectionHeader('Pending', pending.length), ...pending.map(_buildBookingCard)],
          if (confirmed.isNotEmpty) ...[
            _buildSectionHeader('In Rent', confirmed.length),
            ...confirmed.map(_buildBookingCard)
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('Completed', completed.length),
            ...completed.map(_buildBookingCard)
          ],
          if (cancelled.isNotEmpty) ...[
            _buildSectionHeader('Cancelled', cancelled.length),
            ...cancelled.map(_buildBookingCard)
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
                color: softOrangeBg, borderRadius: BorderRadius.circular(12)),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12,
                    color: primaryOrange,
                    fontWeight: FontWeight.bold)),
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
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header
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
                            image: MemoryImage(imageBytes),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageBytes == null
                      ? Icon(
                          booking.vehicleCategory == 'bike'
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          color: primaryOrange,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicleName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "ID: #${booking.id.substring(0, 6).toUpperCase()}",
                        style: const TextStyle(fontSize: 11, color: lightText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_outline, booking.renterName),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_month_outlined,
                  "${booking.dateRangeDisplay} (${booking.rentalDays} days)",
                ),
                const SizedBox(height: 16),

                // Earnings Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Earnings",
                        style: TextStyle(
                          color: lightText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "NPR ${booking.totalPrice.toInt()}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          if (booking.status == 'pending')
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF5F5F5)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _updateBooking(booking.id, 'cancelled'),
                      child: const Text(
                        "Reject",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: const Color(0xFFF5F5F5),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _updateBooking(booking.id, 'confirmed'),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (booking.status != 'pending') const SizedBox(height: 4),
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

  Uint8List? _decodeBase64Image(String base64) {
    try {
      String s = base64.contains(',') ? base64.split(',')[1] : base64;
      return base64Decode(s);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateBooking(String id, String status) async {
    final success = await _bookingController.updateBookingStatus(id, status);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Booking ${status == 'Completed' ? 'In Rent' : 'cancelled'}'),
            backgroundColor: darkText),
      );
      _loadBookings();
    }
  }

}