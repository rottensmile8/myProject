import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/vehicle_controller.dart';
import 'package:werent/auth/edit_vehicle_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyVehiclesScreen extends StatefulWidget {
  final User user;

  const MyVehiclesScreen({super.key, required this.user});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final VehicleController _vehicleController = VehicleController();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  VehicleCategory _selectedCategory = VehicleCategory.car;

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
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleController.getOwnerVehicles(widget.user.id);
      setState(() => _vehicles = vehicles);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Remove this vehicle from your fleet?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _vehicleController.deleteVehicle(vehicleId);
      if (success && mounted) _loadVehicles();
    }
  }

  Future<void> _toggleAvailability(String vehicleId) async {
    final success = await _vehicleController.toggleAvailability(vehicleId);
    if (success && mounted) _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Vehicles', style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: primaryOrange), onPressed: _loadVehicles),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : _buildVehicleList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.garage_rounded, size: 80, color: softOrangeBg),
          const SizedBox(height: 16),
          const Text('No vehicles found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 8),
          const Text('Add your first vehicle to start earning', style: TextStyle(color: lightText)),
        ],
      ),
    );
  }

  List<Vehicle> get filteredVehicles {
    return _vehicles.where((v) => v.category == _selectedCategory).toList();
  }

  Widget _buildVehicleList() {
    return Column(
      children: [
        // Category Selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryTab(Icons.directions_car_rounded, VehicleCategory.car, 'Cars'),
              const SizedBox(width: 12),
              _buildCategoryTab(Icons.two_wheeler_rounded, VehicleCategory.bike, 'Bikes'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVehicles,
            color: primaryOrange,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) => _buildVehicleCard(filteredVehicles[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(IconData icon, VehicleCategory category, String label) {
    final bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : softOrangeBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : primaryOrange),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : darkText, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final imageBytes = Vehicle.safeDecodeImage(vehicle.imageBase64);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                imageBytes != null
                    ? Image.memory(imageBytes, height: 160, width: double.infinity, fit: BoxFit.cover)
                    : _buildPlaceholderHeader(vehicle),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: vehicle.isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      vehicle.isAvailable ? 'Available' : 'Rented',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(vehicle.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
                    Text("NPR ${vehicle.pricePerDayNPR}", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange)),
                  ],
                ),
                Text("${vehicle.brand} • ${vehicle.modelYear}", style: const TextStyle(fontSize: 13, color: lightText)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: primaryOrange),
                    const SizedBox(width: 4),
                    Text(vehicle.pickupLocation, style: const TextStyle(fontSize: 13, color: lightText)),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 243, 239, 235),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: vehicle.isAvailable ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  label: vehicle.isAvailable ? 'Mark as Rented' : 'Mark as Available',
                  color: Colors.amber.shade800,
                  onTap: () => _toggleAvailability(vehicle.id),
                ),
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: Colors.blue,
                  onTap: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditVehicleScreen(user: widget.user, vehicle: vehicle)),
                    );
                    if (res == true) _loadVehicles();
                  },
                ),
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: () => _deleteVehicle(vehicle.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPlaceholderHeader(Vehicle vehicle) {
    return Container(
      height: 160,
      width: double.infinity,
      color: softOrangeBg,
      child: Icon(
        vehicle.category == VehicleCategory.bike ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
        size: 50,
        color: primaryOrange.withOpacity(0.5),
      ),
    );
  }
}