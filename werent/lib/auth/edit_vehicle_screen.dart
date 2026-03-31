import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelYearController;
  late final TextEditingController _priceController;
  late final TextEditingController _pickupLocationController;

  late VehicleCategory _selectedCategory;
  late FuelType _selectedFuelType;
  late Transmission _selectedTransmission;

  // Image state — null means use existing from vehicle
  File? _newImageFile;      // newly picked image
  String? _imageBase64;     // current base64 (existing or new)
  bool _imageRemoved = false;
  bool _isPickingImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameController = TextEditingController(text: v.name);
    _brandController = TextEditingController(text: v.brand);
    _modelYearController = TextEditingController(text: v.modelYear.toString());
    _priceController = TextEditingController(text: v.pricePerDay.toStringAsFixed(0));
    _pickupLocationController = TextEditingController(text: v.pickupLocation);
    _selectedCategory = v.category;
    _selectedFuelType = v.fuelType;
    _selectedTransmission = v.transmission;
    _imageBase64 = v.imageBase64; // pre-populate from existing vehicle
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

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPickingImage = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 768,
        imageQuality: 75,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newImageFile = File(image.path);
          _imageBase64 = base64Encode(bytes);
          _imageRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Select Image Source',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.green.shade700,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  if (_imageBase64 != null)
                    _buildSourceOption(
                      icon: Icons.delete_outline,
                      label: 'Remove',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _newImageFile = null;
                          _imageBase64 = null;
                          _imageRemoved = true;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
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
        imageBase64: _imageBase64,
      );

      final success = await _vehicleController.updateVehicle(updatedVehicle);

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
                  _buildImagePicker(),
                  const SizedBox(height: 16),
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

  Widget _buildImagePicker() {
    // Determine what to show: newly picked file, existing base64, or placeholder
    Widget imageContent;

    if (_isPickingImage) {
      imageContent = const Center(child: CircularProgressIndicator());
    } else if (_newImageFile != null) {
      // Newly picked local file
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_newImageFile!, fit: BoxFit.cover),
            _buildChangeBadge(),
          ],
        ),
      );
    } else if (_imageBase64 != null) {
      // Existing image from server
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(base64Decode(_imageBase64!), fit: BoxFit.cover),
            _buildChangeBadge(),
          ],
        ),
      );
    } else {
      imageContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Tap to add a photo',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Gallery or Camera',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Update the vehicle photo to attract more renters',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isPickingImage ? null : _showImageSourceSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _imageBase64 != null
                        ? Colors.green.shade400
                        : Colors.grey.shade300,
                    width: _imageBase64 != null ? 2 : 1,
                  ),
                ),
                child: imageContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeBadge() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
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
            const Text('Select Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
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
            const Text('Vehicle Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              decoration: _inputDecoration('Model Year', Icons.calendar_today),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter model year';
                final year = int.tryParse(v.trim());
                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: _inputDecoration('Price per Day (NPR)', Icons.attach_money),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter price per day';
                final price = double.tryParse(v.trim());
                if (price == null || price <= 0) return 'Please enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (_selectedCategory == VehicleCategory.car) ...[
              DropdownButtonFormField<FuelType>(
                initialValue: _selectedFuelType,
                decoration: _inputDecoration('Fuel Type', Icons.local_gas_station),
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
                decoration: _inputDecoration('Transmission', Icons.settings),
                items: Transmission.values.map((trans) {
                  return DropdownMenuItem(
                    value: trans,
                    child: Text(trans == Transmission.automatic ? 'Automatic' : 'Manual'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTransmission = v);
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _pickupLocationController,
              decoration: _inputDecoration('Pickup Location', Icons.location_on),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
