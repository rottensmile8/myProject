import 'package:flutter/material.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/vehicle_controller.dart';

class EditVehicleScreen extends StatefulWidget {
  final User user;
  final Vehicle vehicle;

  const EditVehicleScreen({
    super.key,
    required this.user,
    required this.vehicle,
  });

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleController _vehicleController = VehicleController();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelYearController;
  late final TextEditingController _priceController;
  late final TextEditingController _pickupLocationController;

  late VehicleCategory _selectedCategory;
  late FuelType _selectedFuelType;
  late Transmission _selectedTransmission;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameController = TextEditingController(text: v.name);
    _brandController = TextEditingController(text: v.brand);
    _modelYearController =
        TextEditingController(text: v.modelYear.toString());
    _priceController =
        TextEditingController(text: v.pricePerDay.toStringAsFixed(0));
    _pickupLocationController =
        TextEditingController(text: v.pickupLocation);
    _selectedCategory = v.category;
    _selectedFuelType = v.fuelType;
    _selectedTransmission = v.transmission;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelYearController.dispose();
    _priceController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedVehicle = Vehicle(
        id: widget.vehicle.id,
        ownerId: widget.vehicle.ownerId,
        category: _selectedCategory,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        modelYear: int.parse(_modelYearController.text.trim()),
        pricePerDay: double.parse(_priceController.text.trim()),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        pickupLocation: _pickupLocationController.text.trim(),
        isAvailable: widget.vehicle.isAvailable,
        createdAt: widget.vehicle.createdAt,
      );

      final success =
          await _vehicleController.updateVehicle(updatedVehicle);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Update failed: ${_vehicleController.error ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vehicle'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySelection(),
                  const SizedBox(height: 24),
                  _buildVehicleDetailsForm(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Card(
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Category',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    category: VehicleCategory.car,
                    icon: Icons.directions_car,
                    label: 'Car',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryCard(
                    category: VehicleCategory.bike,
                    icon: Icons.two_wheeler,
                    label: 'Bike',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required VehicleCategory category,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          if (category == VehicleCategory.bike) {
            _selectedFuelType = FuelType.petrol;
            _selectedTransmission = Transmission.manual;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.shade100
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.green.shade700
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailsForm() {
    return Card(
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle Details',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Vehicle Name', Icons.label),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter vehicle name'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _brandController,
              decoration: _inputDecoration('Brand', Icons.business),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter brand'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _modelYearController,
              decoration:
                  _inputDecoration('Model Year', Icons.calendar_today),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter model year';
                }
                final year = int.tryParse(v.trim());
                if (year == null ||
                    year < 1900 ||
                    year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: _inputDecoration(
                  'Price per Day (NPR)', Icons.attach_money),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter price per day';
                }
                final price = double.tryParse(v.trim());
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (_selectedCategory == VehicleCategory.car) ...[
              DropdownButtonFormField<FuelType>(
                initialValue: _selectedFuelType,
                decoration: _inputDecoration(
                    'Fuel Type', Icons.local_gas_station),
                items: FuelType.values.map((fuel) {
                  return DropdownMenuItem(
                    value: fuel,
                    child: Text(_getFuelTypeDisplay(fuel)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedFuelType = v);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<Transmission>(
                initialValue: _selectedTransmission,
                decoration:
                    _inputDecoration('Transmission', Icons.settings),
                items: Transmission.values.map((trans) {
                  return DropdownMenuItem(
                    value: trans,
                    child: Text(trans == Transmission.automatic
                        ? 'Automatic'
                        : 'Manual'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedTransmission = v);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _pickupLocationController,
              decoration:
                  _inputDecoration('Pickup Location', Icons.location_on),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter pickup location'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  String _getFuelTypeDisplay(FuelType fuel) {
    switch (fuel) {
      case FuelType.petrol:
        return 'Petrol';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.electric:
        return 'Electric';
      case FuelType.hybrid:
        return 'Hybrid';
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitEdit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Changes',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
