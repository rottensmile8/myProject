import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/vehicle_controller.dart';
import 'package:werent/controllers/booking_controller.dart';

// Global in-memory saved vehicles store (session-local, persists while app is open)
final Set<String> globalSavedVehicleIds = {};
final List<Vehicle> globalSavedVehicles = [];

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
    List<Vehicle> vehicles = _selectedCategory == null
        ? _vehicles
        : _vehicles.where((v) => v.category == _selectedCategory).toList();

    // Sort: available first, rented last
    final available = vehicles.where((v) => v.isAvailable).toList();
    final rented = vehicles.where((v) => !v.isAvailable).toList();
    return [...available, ...rented];
  }

  List<Vehicle> get availableVehicles =>
      filteredVehicles.where((v) => v.isAvailable).toList();

  List<Vehicle> get rentedVehicles =>
      filteredVehicles.where((v) => !v.isAvailable).toList();

  bool _isSaved(String vehicleId) => globalSavedVehicleIds.contains(vehicleId);

  void _toggleSave(Vehicle vehicle) {
    setState(() {
      if (globalSavedVehicleIds.contains(vehicle.id)) {
        globalSavedVehicleIds.remove(vehicle.id);
        globalSavedVehicles.removeWhere((v) => v.id == vehicle.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.white),
                SizedBox(width: 8),
                Text('Removed from saved vehicles'),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        globalSavedVehicleIds.add(vehicle.id);
        // Replace any existing entry to keep list fresh
        globalSavedVehicles.removeWhere((v) => v.id == vehicle.id);
        globalSavedVehicles.add(vehicle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text('Saved to your vehicles'),
              ],
            ),
            backgroundColor: Colors.pink.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
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

    // Check if user is approved
    if (!widget.user!.isActive) {
      _showApprovalRequiredDialog(context);
      return;
    }

    // Step 1: Show Terms & Conditions agreement dialog
    final agreed = await _showRentalAgreementDialog(vehicle);
    if (!agreed || !mounted) return;

    // Step 2: Show booking date picker dialog
    await _showDatePickerDialog(vehicle);
  }

  /// Shows the Rental Terms & Conditions dialog.
  /// Returns true if the user agreed, false if they cancelled.
  Future<bool> _showRentalAgreementDialog(Vehicle vehicle) async {
    bool accepted = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool checkboxValue = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                child: const Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.white, size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rental Agreement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Please read and accept the terms before booking ${vehicle.name}.',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _rentalTermsText(),
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () =>
                          setDialogState(() => checkboxValue = !checkboxValue),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: checkboxValue,
                              activeColor: Colors.blue.shade700,
                              onChanged: (val) => setDialogState(
                                  () => checkboxValue = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Rental Terms & Conditions.',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: checkboxValue
                      ? () {
                          accepted = true;
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Proceed to Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return accepted;
  }

  String _rentalTermsText() {
    return '''
1. ELIGIBILITY
The renter must be at least 18 years old and possess a valid driving license appropriate for the vehicle category being rented.

2. BOOKING & PAYMENT
Booking is confirmed only after the owner's approval. Full payment of the agreed rental amount (NPR) must be made at pickup unless otherwise arranged. The total price shown is inclusive of the rental period selected.

3. VEHICLE USE
The renter agrees to use the vehicle only for lawful purposes and within the territory of Nepal. Sub-renting, racing, or off-road use is strictly prohibited unless the vehicle is explicitly listed for such use.

4. FUEL & MAINTENANCE
The vehicle must be returned in the same fuel level and condition as received. Any damage, excessive dirt, or fuel deficiency will be charged to the renter.

5. DAMAGE & LIABILITY
The renter is fully responsible for any damage caused to the vehicle during the rental period, including accidental damage, theft, or vandalism. The owner's insurance, if any, does not cover renter negligence.

6. CANCELLATION POLICY
Cancellations made more than 24 hours before the start date will receive a full refund. Cancellations within 24 hours may be subject to a cancellation fee as determined by the owner.

7. LATE RETURN
Vehicles returned after the agreed end date will incur additional charges at the daily rental rate for each extra day or part thereof.

8. TRAFFIC VIOLATIONS & FINES
Any traffic violations, fines, or penalties incurred during the rental period are solely the renter's responsibility.

9. ACCIDENTS
In the event of an accident, the renter must immediately notify the owner and relevant authorities. A full report must be provided to the owner within 24 hours.

10. GOVERNING LAW
This agreement is governed by the laws of Nepal. Any disputes shall be settled under the jurisdiction of the courts of Nepal.

By proceeding with this booking, you acknowledge that you have read, understood, and agree to all the terms and conditions stated above.
''';
  }

  Future<void> _showDatePickerDialog(Vehicle vehicle) async {
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
                            if (endDate != null &&
                                endDate!.isBefore(startDate!)) {
                              endDate = null;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
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
                  child: const Text('Proceed to Payment'),
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
                date != null ? '${date.day}/${date.month}/${date.year}' : label,
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
      vehicleCategory:
          vehicle.category == VehicleCategory.bike ? 'bike' : 'car',
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
                            child: ListView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                // Available section
                                if (availableVehicles.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    'Available',
                                    availableVehicles.length,
                                    Colors.green,
                                    Icons.check_circle_outline,
                                  ),
                                  ...availableVehicles
                                      .map((v) => _buildVehicleCard(v)),
                                ],
                                // Rented section
                                if (rentedVehicles.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    'Rented',
                                    rentedVehicles.length,
                                    Colors.red,
                                    Icons.lock_clock,
                                  ),
                                  ...rentedVehicles
                                      .map((v) => _buildVehicleCard(v)),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
    final saved = _isSaved(vehicle.id);
    final imageBytes = Vehicle.safeDecodeImage(vehicle.imageBase64);
    final hasImage = imageBytes != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle image or icon banner
          if (hasImage)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Vehicle.safeDecodeImage(vehicle.imageBase64) != null
                  ? Image.memory(
                      Vehicle.safeDecodeImage(vehicle.imageBase64)!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('🖼️ BrowseVehicles Image error: $error');
                        return _buildImageErrorBanner(vehicle);
                      },
                    )
                  : _buildImageErrorBanner(vehicle),
            )
          else
            _buildVehicleIconBanner(vehicle),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('${vehicle.brand} • ${vehicle.modelYear}'),
                          if (vehicle.ownerName != null &&
                              vehicle.ownerName!.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Text(
                                  vehicle.ownerName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(vehicle.isAvailable),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildInfoTag(
                        'NPR ${vehicle.pricePerDay.toStringAsFixed(0)}/day'),
                    _buildInfoTag(vehicle.fuelTypeDisplay),
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
                // Book Now button + Favourite icon
                Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 8),
                    // Favourite / Save button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color:
                            saved ? Colors.pink.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: saved
                              ? Colors.pink.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _toggleSave(vehicle),
                        icon: Icon(
                          saved ? Icons.favorite : Icons.favorite_border,
                          color: saved
                              ? Colors.pink.shade600
                              : Colors.grey.shade500,
                          size: 22,
                        ),
                        tooltip: saved ? 'Remove from saved' : 'Save vehicle',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleIconBanner(Vehicle vehicle) {
    final assetPath = vehicle.category == VehicleCategory.bike
        ? 'assets/images/bike.svg'
        : 'assets/images/car.svg';

    debugPrint('🔍 BrowseVehicles: Loading asset banner $assetPath');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Image.asset(
        assetPath,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('🖼️ Browse Asset failed ($assetPath): $error');
          return SvgPicture.asset(
            assetPath,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholderBuilder: (context) {
              debugPrint('Browse SVG failed - using icon: $assetPath');
              return Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(
                  vehicle.category == VehicleCategory.bike
                      ? Icons.two_wheeler
                      : Icons.directions_car,
                  color: Colors.blue.shade300,
                  size: 52,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageErrorBanner(Vehicle vehicle) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.red.shade600, size: 48),
          const SizedBox(height: 8),
          Text(
            'Image Error',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            '${vehicle.name} - Check console',
            style: TextStyle(color: Colors.red.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showApprovalRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approval Required'),
        content: const Text(
          'Your account is currently pending admin approval. You can browse vehicles, but booking is disabled until your account is activated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
