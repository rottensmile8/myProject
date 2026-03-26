import 'package:flutter/material.dart';
import 'package:werent/models/vehicle_model.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/vehicle_controller.dart';

class AddVehicleScreen extends StatefulWidget {
  final User user;

  const AddVehicleScreen({super.key, required this.user});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleController _vehicleController = VehicleController();

  // Form controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelYearController = TextEditingController();
  final _priceController = TextEditingController();
  final _pickupLocationController = TextEditingController();

  // Selected values
  VehicleCategory _selectedCategory = VehicleCategory.car;
  FuelType _selectedFuelType = FuelType.petrol;
  Transmission _selectedTransmission = Transmission.manual;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelYearController.dispose();
    _priceController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if user is approved
    if (!widget.user.isActive) {
      _showApprovalRequiredDialog(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicle = await _vehicleController.addVehicle(
        ownerId: widget.user.id,
        category: _selectedCategory,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        modelYear: int.parse(_modelYearController.text.trim()),
        pricePerDay: double.parse(_priceController.text.trim()),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        pickupLocation: _pickupLocationController.text.trim(),
      );

      if (vehicle != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showApprovalRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approval Required'),
        content: const Text(
          'Your account is currently pending admin approval. You can view your dashboard, but adding new vehicles is disabled until your account is activated.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
          // Reset fuel type and transmission when switching to bike
          if (category == VehicleCategory.bike) {
            _selectedFuelType = FuelType.petrol;
            _selectedTransmission = Transmission.manual;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Vehicle Name', Icons.label),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter vehicle name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Brand
            TextFormField(
              controller: _brandController,
              decoration: _inputDecoration('Brand', Icons.business),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter brand';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Model Year
            TextFormField(
              controller: _modelYearController,
              decoration: _inputDecoration('Model Year', Icons.calendar_today),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter model year';
                }
                final year = int.tryParse(value.trim());
                if (year == null ||
                    year < 1900 ||
                    year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price per day
            TextFormField(
              controller: _priceController,
              decoration: _inputDecoration(
                'Price per Day (NPR)',
                Icons.attach_money,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price per day';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fuel Type (only for cars)
            if (_selectedCategory == VehicleCategory.car) ...[
              DropdownButtonFormField<FuelType>(
                initialValue: _selectedFuelType,
                decoration: _inputDecoration(
                  'Fuel Type',
                  Icons.local_gas_station,
                ),
                items: FuelType.values.map((fuel) {
                  return DropdownMenuItem(
                    value: fuel,
                    child: Text(_getFuelTypeDisplay(fuel)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFuelType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Transmission (only for cars)
              DropdownButtonFormField<Transmission>(
                initialValue: _selectedTransmission,
                decoration: _inputDecoration('Transmission', Icons.settings),
                items: Transmission.values.map((trans) {
                  return DropdownMenuItem(
                    value: trans,
                    child: Text(
                      trans == Transmission.automatic ? 'Automatic' : 'Manual',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTransmission = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Pickup Location
            TextFormField(
              controller: _pickupLocationController,
              decoration: _inputDecoration(
                'Pickup Location',
                Icons.location_on,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter pickup location';
                }
                return null;
              },
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        onPressed: _isLoading ? null : _submitVehicle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Add Vehicle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
