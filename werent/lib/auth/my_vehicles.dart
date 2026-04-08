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
      final vehicles = await _vehicleController.getOwnerVehicles(
        widget.user.id,
      );
      setState(() {
        _vehicles = vehicles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: ${e.toString()}'),
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

  Future<void> _deleteVehicle(String vehicleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _vehicleController.deleteVehicle(vehicleId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVehicles();
      }
    }
  }

  Future<void> _toggleAvailability(String vehicleId) async {
    final success = await _vehicleController.toggleAvailability(vehicleId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability updated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadVehicles),
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
            : _vehicles.isEmpty
                ? _buildEmptyState()
                : _buildVehicleList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No vehicles yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first vehicle to start renting',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryTab(
                Icons.directions_car,
                VehicleCategory.car,
                'Cars',
              ),
              _buildCategoryTab(
                Icons.two_wheeler,
                VehicleCategory.bike,
                'Bikes',
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVehicles,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = filteredVehicles[index];
                return _buildVehicleCard(vehicle);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(
    IconData icon,
    VehicleCategory category,
    String label,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedCategory == category
              ? Colors.green.shade400
              : Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final imageBytes = Vehicle.safeDecodeImage(vehicle.imageBase64);
    final hasImage = imageBytes != null;

    Widget? imageHeader;
    if (hasImage) {
      imageHeader = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.memory(
          imageBytes!,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('🖼️ MyVehicles Image error: $error');
            return _buildAssetOrIconHeader(vehicle);
          },
        ),
      );
    } else {
      imageHeader = _buildAssetOrIconHeader(vehicle);
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          imageHeader,
          // Name, brand, year + availability
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${vehicle.brand} • ${vehicle.modelYear}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: vehicle.isAvailable
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vehicle.isAvailable ? 'Available' : 'Rented',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: vehicle.isAvailable
                          ? Colors.green.shade700
                          : const Color.fromARGB(255, 198, 73, 73),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Vehicle details —  use Wrap to prevent overflow
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _buildDetailItem(
                      Icons.attach_money,
                      vehicle.pricePerDayNPR,
                    ),
                    if (vehicle.category == VehicleCategory.car) ...[
                      _buildDetailItem(
                        Icons.local_gas_station,
                        vehicle.fuelTypeDisplay,
                      ),
                      _buildDetailItem(
                        Icons.settings,
                        vehicle.transmissionDisplay,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _buildDetailItem(Icons.location_on, vehicle.pickupLocation),
              ],
            ),
          ),
          // Action buttons
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _toggleAvailability(vehicle.id),
                    icon: Icon(
                      vehicle.isAvailable
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      color: Colors.orange,
                    ),
                    label: Text(
                      vehicle.isAvailable
                          ? 'Mark as Rented'
                          : 'Mark as Available',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditVehicleScreen(
                            user: widget.user,
                            vehicle: vehicle,
                          ),
                        ),
                      );
                      if (result == true) _loadVehicles();
                    },
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteVehicle(vehicle.id),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete',
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

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildAssetOrIconHeader(Vehicle vehicle) {
    final assetPath = vehicle.category == VehicleCategory.bike
        ? 'assets/images/bike.svg'
        : 'assets/images/car.svg';

    debugPrint('🔍 Loading asset header: $assetPath for ${vehicle.name}');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Image.asset(
        assetPath,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('🖼️ Asset Image failed ($assetPath): $error');
          // Fallback to SVG
          return SvgPicture.asset(
            assetPath,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholderBuilder: (context) {
              debugPrint('⚠️ SVG also failed for $assetPath - using icon');
              return Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(
                  vehicle.category == VehicleCategory.bike
                      ? Icons.two_wheeler
                      : Icons.directions_car,
                  size: 40,
                  color: Colors.green.shade400,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
