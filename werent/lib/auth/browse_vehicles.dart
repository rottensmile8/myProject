import 'package:flutter/material.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/controllers/vehicle_controller.dart';

class BrowseVehiclesScreen extends StatefulWidget {
  const BrowseVehiclesScreen({super.key});

  @override
  State<BrowseVehiclesScreen> createState() => _BrowseVehiclesScreenState();
}

class _BrowseVehiclesScreenState extends State<BrowseVehiclesScreen> {
  final VehicleController _vehicleController = VehicleController();
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
        // Force the container to fill the screen for the gradient to look right
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
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoTag('Rs ${vehicle.pricePerDayNPR}/day'),
                const SizedBox(width: 8),
                _buildInfoTag(vehicle.fuelTypeDisplay),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vehicle.isAvailable ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Book Now'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
