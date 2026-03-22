import 'package:flutter/material.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/vehicle_controller.dart';
import 'package:werent/controllers/booking_controller.dart';

class BrowseVehiclesScreen extends StatefulWidget {
  final User? user;

  const BrowseVehiclesScreen({super.key, this.user});

  @override
  State<BrowseVehiclesScreen> createState() => _BrowseVehiclesScreenState();
}

class _BrowseVehiclesScreenState extends State<BrowseVehiclesScreen> {
  final VehicleController _vehicleController = VehicleController();
  final BookingController _bookingController = BookingController();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  VehicleCategory? _selectedCategory = VehicleCategory.car;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await _vehicleController.getOwnerVehicles('');
      setState(() {
        _vehicles = vehicles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: $e'),
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

  List<Vehicle> get filteredVehicles {
    if (_selectedCategory == null) return _vehicles;
    return _vehicles.where((v) => v.category == _selectedCategory).toList();
  }

  Future<void> _showBookingDialog(Vehicle vehicle) async {
    // If no user is logged in, prompt login
    if (widget.user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You need to be logged in to book a vehicle.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/auth');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    DateTime? startDate;
    DateTime? endDate;
    double totalPrice = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int rentalDays = (startDate != null && endDate != null)
                ? endDate!.difference(startDate!).inDays + 1
                : 0;
            totalPrice = rentalDays * vehicle.pricePerDay;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          vehicle.category == VehicleCategory.bike
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            vehicle.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                      style: TextStyle(
                        color: Colors.blue.shade100,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Select Dates',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Start Date
                    _buildDateSelector(
                      label: 'Start Date',
                      date: startDate,
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                            // Reset end date if it's before new start
                            if (endDate != null &&
                                endDate!.isBefore(startDate!)) {
                              endDate = null;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    // End Date
                    _buildDateSelector(
                      label: 'End Date',
                      date: endDate,
                      icon: Icons.calendar_month,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Price Summary
                    if (rentalDays > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$rentalDays day${rentalDays > 1 ? 's' : ''} × Rs ${vehicle.pricePerDay.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Rs ${totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 14,
                              color: Colors.blue.shade200,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'NPR ${totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (startDate == null || endDate == null)
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _confirmBooking(
                            vehicle: vehicle,
                            startDate: startDate!,
                            endDate: endDate!,
                            totalPrice: totalPrice,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirm Booking'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : label,
                style: TextStyle(
                  color: date != null ? Colors.black87 : Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking({
    required Vehicle vehicle,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    final user = widget.user!;

    // Show loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Sending booking request...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    final booking = await _bookingController.createBooking(
      vehicleId: vehicle.id,
      vehicleName: vehicle.name,
      vehicleCategory: vehicle.category == VehicleCategory.bike ? 'bike' : 'car',
      renterId: user.id,
      renterName: user.fullName,
      renterEmail: user.email,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Booking request sent for ${vehicle.name}! The owner will confirm shortly.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to send booking: ${_bookingController.error ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Vehicles'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadVehicles),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade50,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Column(
                children: [
                  _buildCategoryFilter(),
                  Expanded(
                    child: filteredVehicles.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadVehicles,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredVehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = filteredVehicles[index];
                                return _buildVehicleCard(vehicle);
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCategoryTab(
            Icons.directions_car,
            VehicleCategory.car,
            'Cars',
          ),
          const SizedBox(width: 16),
          _buildCategoryTab(
            Icons.two_wheeler,
            VehicleCategory.bike,
            'Bikes',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(
      IconData icon, VehicleCategory category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.blue.shade400,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue.shade700 : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined,
                size: 80, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            const Text(
              'No Vehicles Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Try adjusting your filters or refresh.'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle.category == VehicleCategory.bike
                        ? Icons.two_wheeler
                        : Icons.directions_car,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('${vehicle.brand} • ${vehicle.modelYear}'),
                    ],
                  ),
                ),
                _buildStatusBadge(vehicle.isAvailable),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoTag('Rs ${vehicle.pricePerDayNPR}'),
                const SizedBox(width: 8),
                _buildInfoTag(vehicle.fuelTypeDisplay),
                const SizedBox(width: 8),
                _buildInfoTag(vehicle.transmissionDisplay),
              ],
            ),
            const SizedBox(height: 8),
            if (vehicle.pickupLocation.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      vehicle.pickupLocation,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vehicle.isAvailable
                    ? () => _showBookingDialog(vehicle)
                    : null,
                icon: const Icon(Icons.book_online, size: 18),
                label: const Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: available ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Available' : 'Rented',
        style: TextStyle(
          color: available ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
