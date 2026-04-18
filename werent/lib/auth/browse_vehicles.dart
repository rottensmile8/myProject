import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart'
    show canLaunchUrl, LaunchMode, launchUrl;
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/vehicle_controller.dart';
import 'package:werent/controllers/booking_controller.dart';
import 'package:werent/services/khalti_service.dart';

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

  // Theme Palette
  static const Color primaryOrange = Color(0xFFFF8A00);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color softOrangeBg = Color(0xFFFFF5E9);
  static const Color darkText = Color(0xFF3E2723);
  static const Color lightText = Color(0xFF8D6E63);

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
            backgroundColor: darkText,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        globalSavedVehicleIds.add(vehicle.id);
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
            backgroundColor: primaryOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _showBookingDialog(Vehicle vehicle) async {
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
              child:
                  const Text('Login', style: TextStyle(color: primaryOrange)),
            ),
          ],
        ),
      );
      return;
    }

    if (!widget.user!.isActive) {
      _showApprovalRequiredDialog(context);
      return;
    }

    final hasActive = await _bookingController.hasActiveRental(widget.user!.id);
    if (hasActive) {
      _showActiveRentalDialog(context);
      return;
    }

    final agreed = await _showRentalAgreementDialog(vehicle);
    if (!agreed || !mounted) return;

    await _showDatePickerDialog(vehicle);
  }

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
                decoration: const BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Colors.white, size: 26),
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
                      style: TextStyle(color: lightText, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: softOrangeBg,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: primaryOrange.withOpacity(0.3)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _rentalTermsText(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.6,
                            color: darkText,
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
                              activeColor: primaryOrange,
                              onChanged: (val) => setDialogState(
                                  () => checkboxValue = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Rental Terms & Conditions.',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: darkText),
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
                  child:
                      const Text('Cancel', style: TextStyle(color: lightText)),
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
                    backgroundColor: primaryOrange,
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
The renter must be at least 18 years old and possess a valid driving license.

2. BOOKING & PAYMENT
Booking is confirmed only after the owner's approval. Full payment via Khalti is required.

3. VEHICLE USE
Lawful purposes within Nepal only. Racing or sub-renting is strictly prohibited.

4. DAMAGE & LIABILITY
Renter is fully responsible for damages, theft, or vandalism during the rental period.

5. CANCELLATION POLICY
Full refund if cancelled >24h before. 10% fee if within 24h.

6. LATE RETURN
Daily rates apply for extra days.

7. TRAFFIC VIOLATIONS
Fines incurred are solely the renter's responsibility.

8. ACCIDENTS
Notify owner immediately. Report must be provided within 24 hours.

9. GOVERNING LAW
Nepal jurisdiction applies.
''';
  }

  Future<void> _showActiveRentalDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: primaryOrange),
            SizedBox(width: 8),
            Text('You have Active Rental'),
          ],
        ),
        content: const Text(
            'You already have an active vehicle rental. Please complete or return it first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/renter/saved-vehicles'),
            icon: const Icon(Icons.favorite),
            label: const Text('View Saved Vehicles'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 234, 138, 21)),
          ),
        ],
      ),
    );
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
                  borderRadius: BorderRadius.circular(20)),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
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
                            child: Text(vehicle.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                      ],
                    ),
                    Text('Rs ${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                        style:
                            const TextStyle(color: surfaceWhite, fontSize: 14)),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                DateTime.now().add(const Duration(days: 365)));
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                            if (endDate != null &&
                                endDate!.isBefore(startDate!)) endDate = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
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
                                DateTime.now().add(const Duration(days: 365)));
                        if (picked != null)
                          setDialogState(() => endDate = picked);
                      },
                    ),
                    if (rentalDays > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: softOrangeBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryOrange.withOpacity(0.3))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkText)),
                            Text('NPR ${totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryOrange,
                                    fontSize: 18)),
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
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: (startDate == null || endDate == null)
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _confirmBooking(
                              vehicle: vehicle,
                              startDate: startDate!,
                              endDate: endDate!,
                              totalPrice: totalPrice);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Pay with Khalti',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector(
      {required String label,
      required DateTime? date,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: primaryOrange.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(10),
          color: surfaceWhite,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: primaryOrange),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : label,
                    style: TextStyle(
                        color: date != null ? darkText : lightText,
                        fontSize: 14))),
            const Icon(Icons.arrow_drop_down, color: lightText),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking(
      {required Vehicle vehicle,
      required DateTime startDate,
      required DateTime endDate,
      required double totalPrice}) async {
    final user = widget.user!;
    final int khaltiAmount = (totalPrice * 100).toInt();

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redirecting to Khalti...')));

    final paymentUrl = await KhaltiService.createPayment(
      amount: khaltiAmount,
      orderId: "WR-${DateTime.now().millisecondsSinceEpoch}",
      orderName: vehicle.name,
    );

    if (paymentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment initiation failed'),
          backgroundColor: Colors.red));
      return;
    }

    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(booking != null ? 'Booking Successfull!' : 'Booking failed'),
        backgroundColor: booking != null ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        title: const Text('Browse Vehicles',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkText)),
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded, color: primaryOrange),
              onPressed: _loadVehicles),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : Column(
              children: [
                _buildCategoryFilter(),
                Expanded(
                  child: filteredVehicles.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadVehicles,
                          color: primaryOrange,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (availableVehicles.isNotEmpty) ...[
                                _buildSectionHeader(
                                    'Available',
                                    availableVehicles.length,
                                    Colors.green,
                                    Icons.check_circle_outline),
                                ...availableVehicles
                                    .map((v) => _buildVehicleCard(v)),
                              ],
                              if (rentedVehicles.isNotEmpty) ...[
                                _buildSectionHeader(
                                    'Rented',
                                    rentedVehicles.length,
                                    Colors.red,
                                    Icons.lock_clock),
                                ...rentedVehicles
                                    .map((v) => _buildVehicleCard(v)),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
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
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(),
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
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
              Icons.directions_car_rounded, VehicleCategory.car, 'Cars'),
          const SizedBox(width: 16),
          _buildCategoryTab(
              Icons.two_wheeler_rounded, VehicleCategory.bike, 'Bikes'),
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
          color: isSelected ? primaryOrange : softOrangeBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: isSelected ? Colors.white : primaryOrange),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : darkText,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child: Text('No Vehicles Found',
            style: TextStyle(fontSize: 18, color: lightText)));
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final saved = _isSaved(vehicle.id);
    final imageBytes = Vehicle.safeDecodeImage(vehicle.imageBase64);

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
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: imageBytes != null
                ? Image.memory(imageBytes,
                    height: 160, width: double.infinity, fit: BoxFit.cover)
                : _buildVehicleIconBanner(vehicle),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(vehicle.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkText))),
                    _buildStatusBadge(vehicle.isAvailable),
                  ],
                ),
                Text("${vehicle.brand} • ${vehicle.modelYear}",
                    style: const TextStyle(fontSize: 13, color: lightText)),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: vehicle.isAvailable
                            ? () => _showBookingDialog(vehicle)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Book Now',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _toggleSave(vehicle),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: saved ? const Color(0xFFFFEBEE) : softOrangeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: saved
                                  ? Colors.red.shade200
                                  : primaryOrange.withOpacity(0.1)),
                        ),
                        child: Icon(
                            saved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: saved ? Colors.red : primaryOrange),
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
    return Container(
      height: 160,
      width: double.infinity,
      color: softOrangeBg,
      child: Icon(
          vehicle.category == VehicleCategory.bike
              ? Icons.two_wheeler_rounded
              : Icons.directions_car_rounded,
          size: 50,
          color: primaryOrange.withOpacity(0.5)),
    );
  }

  void _showApprovalRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approval Required'),
        content: const Text(
            'Your account is pending admin approval. Booking is disabled until then.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: available ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(8)),
      child: Text(available ? 'Available' : 'Rented',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: softOrangeBg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: darkText, fontWeight: FontWeight.w500)),
    );
  }
}
