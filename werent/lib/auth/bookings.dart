import 'package:flutter/material.dart';
import 'package:werent/models/booking_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/booking_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookings = await _bookingController.getOwnerBookings(
        widget.user.id,
      );
      setState(() {
        _bookings = bookings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: Colors.green.shade700,
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
            colors: [Colors.green.shade700, Colors.green.shade50],
            stops: const [0.0, 0.3],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
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
          Icon(
            Icons.book_online_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bookings will appear here when customers rent your vehicles',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    // Group bookings by status
    final pendingBookings = _bookings
        .where((b) => b.status == 'pending')
        .toList();
    final confirmedBookings = _bookings
        .where((b) => b.status == 'confirmed')
        .toList();
    final completedBookings = _bookings
        .where((b) => b.status == 'completed')
        .toList();
    final cancelledBookings = _bookings
        .where((b) => b.status == 'cancelled')
        .toList();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingBookings.isNotEmpty) ...[
            _buildSectionHeader('Pending', pendingBookings.length),
            ...pendingBookings.map((booking) => _buildBookingCard(booking)),
          ],
          if (confirmedBookings.isNotEmpty) ...[
            _buildSectionHeader('Confirmed', confirmedBookings.length),
            ...confirmedBookings.map((booking) => _buildBookingCard(booking)),
          ],
          if (completedBookings.isNotEmpty) ...[
            _buildSectionHeader('Completed', completedBookings.length),
            ...completedBookings.map((booking) => _buildBookingCard(booking)),
          ],
          if (cancelledBookings.isNotEmpty) ...[
            _buildSectionHeader('Cancelled', cancelledBookings.length),
            ...cancelledBookings.map((booking) => _buildBookingCard(booking)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
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
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Booking header
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
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    booking.vehicleCategory == 'bike'
                        ? Icons.two_wheeler
                        : Icons.directions_car,
                    size: 28,
                    color: _getStatusColor(booking.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicleName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Booking #${booking.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(booking.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Renter info
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.renterName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Email
                Row(
                  children: [
                    const Icon(Icons.email, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.renterEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Date range
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booking.dateRangeDisplay,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${booking.rentalDays} day${booking.rentalDays > 1 ? 's' : ''})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Total price
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'NPR ${booking.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons for pending bookings
          if (booking.status == 'pending')
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final success = await _bookingController
                            .updateBookingStatus(booking.id, 'confirmed');
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking confirmed'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadBookings();
                        }
                      },
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final success = await _bookingController
                            .updateBookingStatus(booking.id, 'cancelled');
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking cancelled'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          _loadBookings();
                        }
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
