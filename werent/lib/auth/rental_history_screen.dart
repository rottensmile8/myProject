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
            content: Text('Error loading history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Uint8List? _decodeBase64Image(String base64) {
    final bytes = Vehicle.safeDecodeImage(base64);
    if (bytes == null) {
      debugPrint(
          '🖼️ RentalHistory decode failed for booking: $base64.substring(0, 50)....');
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental History'),
        backgroundColor: const Color.fromARGB(255, 31, 162, 59),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 31, 162, 59),
              Colors.purple.shade50
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _bookings.isEmpty
                ? _buildEmptyState()
                : _buildBookingList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined,
              size: 80, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No Rental History',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Your confirmed and completed rentals will appear here',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    // Order: confirmed → pending → completed → cancelled
    final confirmed = _bookings.where((b) => b.status == 'confirmed').toList();
    final pending = _bookings.where((b) => b.status == 'pending').toList();
    final completed = _bookings.where((b) => b.status == 'completed').toList();
    final cancelled = _bookings.where((b) => b.status == 'cancelled').toList();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (confirmed.isNotEmpty) ...[
            _buildSectionHeader('Confirmed', confirmed.length, Colors.green),
            ...confirmed.map((b) => _buildBookingCard(b)),
          ],
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('Pending', pending.length, Colors.orange),
            ...pending.map((b) => _buildBookingCard(b)),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('Completed', completed.length, Colors.blue),
            ...completed.map((b) => _buildBookingCard(b)),
          ],
          if (cancelled.isNotEmpty) ...[
            _buildSectionHeader('Cancelled', cancelled.length, Colors.red),
            ...cancelled.map((b) => _buildBookingCard(b)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: booking.vehicleImageBase64 != null
                        ? _decodeBase64Image(booking.vehicleImageBase64!) !=
                                null
                            ? DecorationImage(
                                image: MemoryImage(_decodeBase64Image(
                                    booking.vehicleImageBase64!)!),
                                fit: BoxFit.cover,
                              )
                            : null
                        : null,
                  ),
                  child: (booking.vehicleImageBase64 == null ||
                          _decodeBase64Image(booking.vehicleImageBase64!) ==
                              null)
                      ? Icon(
                          booking.vehicleCategory == 'bike'
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          size: 28,
                          color: statusColor,
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
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Booking #${booking.id.substring(0, 8)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      booking.dateRangeDisplay,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${booking.rentalDays} day${booking.rentalDays > 1 ? 's' : ''})',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (booking.isCurrentlyRented) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            const Text(
                              'In Rent',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (booking.isCurrentlyRented) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '${booking.daysRemaining} days remaining in your rental',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'NPR ${booking.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 18, 36, 173),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          if (booking.status == 'completed' ||
              booking.status == 'cancelled' ||
              booking.isOverdue)
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _confirmDelete(booking),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Remove from history',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History?'),
        content: Text(
            'Are you sure you want to remove the rental record for ${booking.vehicleName} from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _bookingController.deleteBooking(booking.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${_bookingController.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
