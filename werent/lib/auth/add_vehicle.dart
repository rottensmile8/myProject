import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  // Theme Palette
  static const Color primaryOrange = Color(0xFFFF8A00);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color softOrangeBg = Color(0xFFFFF5E9);
  static const Color darkText = Color(0xFF3E2723);
  static const Color lightText = Color(0xFF8D6E63);

  // Form controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelYearController = TextEditingController();
  final _priceController = TextEditingController();
  final _pickupLocationController = TextEditingController();

  VehicleCategory _selectedCategory = VehicleCategory.car;
  FuelType _selectedFuelType = FuelType.petrol;
  Transmission _selectedTransmission = Transmission.manual;

  File? _selectedImage;
  String? _imageBase64;
  bool _isPickingImage = false;
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

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPickingImage = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large! Max 2MB supported.'), backgroundColor: primaryOrange),
            );
          }
          return;
        }
        setState(() {
          _selectedImage = File(image.path);
          _imageBase64 = base64Encode(bytes);
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
        title: const Text('Add Vehicle', style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Vehicle Photo'),
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildSectionTitle('Category'),
              _buildCategorySelection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Vehicle Details'),
              _buildVehicleDetailsForm(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isPickingImage ? null : _showImageSourceSheet,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: softOrangeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _selectedImage != null ? primaryOrange : Colors.transparent, width: 2),
        ),
        child: _isPickingImage
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_rounded, size: 48, color: primaryOrange),
                      const SizedBox(height: 8),
                      Text('Upload Vehicle Image', style: TextStyle(color: lightText, fontWeight: FontWeight.w600)),
                    ],
                  ),
      ),
    );
  }

// vehicle category
  Widget _buildCategorySelection() {
    return Row(
      children: [
        Expanded(child: _buildCategoryCard(VehicleCategory.car, Icons.directions_car_rounded, 'Car')),
        const SizedBox(width: 16),
        Expanded(child: _buildCategoryCard(VehicleCategory.bike, Icons.two_wheeler_rounded, 'Bike')),
      ],
    );
  }

  Widget _buildCategoryCard(VehicleCategory category, IconData icon, String label) {
    final bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : softOrangeBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : primaryOrange),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : darkText, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailsForm() {
    return Column(
      children: [
        _buildThemedField(_nameController, 'Vehicle Name', Icons.drive_file_rename_outline_rounded),
        const SizedBox(height: 16),
        _buildThemedField(_brandController, 'Brand (e.g. Toyota, Honda)', Icons.business_rounded),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildThemedField(_modelYearController, 'Year', Icons.calendar_today_rounded, isNumber: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildThemedField(_priceController, 'Price/Day', Icons.payments_outlined, isNumber: true)),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedCategory == VehicleCategory.car) ...[
          _buildDropdown<FuelType>(
            label: 'Fuel Type',
            value: _selectedFuelType,
            items: FuelType.values,
            onChanged: (v) => setState(() => _selectedFuelType = v!),
          ),
          const SizedBox(height: 16),
        if (_selectedCategory == VehicleCategory.bike) ...[
          _buildDropdown<FuelType>(
            label: 'Fuel Type',
            value: _selectedFuelType,
            items: FuelType.values,
            onChanged: (v) => setState(() => _selectedFuelType = v!),
          ),
          const SizedBox(height: 16),
        ],

        _buildThemedField(_pickupLocationController, 'Pickup Location', Icons.location_on_outlined),
      ],
      ]
    );
  }

  Widget _buildThemedField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: Icon(icon, color: primaryOrange, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: primaryOrange, width: 1.5)),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown<T>({required String label, required T value, required List<T> items, required ValueChanged<T?> onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString().split('.').last.toUpperCase()))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: lightText),
        prefixIcon: const Icon(Icons.settings_input_component_rounded, color: primaryOrange),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: primaryOrange, width: 1.5)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitVehicle,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text('List Vehicle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Source", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceBtn(Icons.photo_library_rounded, "Gallery", () => _pickImage(ImageSource.gallery)),
                _buildSourceBtn(Icons.camera_alt_rounded, "Camera", () => _pickImage(ImageSource.camera)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: softOrangeBg, shape: BoxShape.circle),
            child: Icon(icon, color: primaryOrange, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
        ],
      ),
    );
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.user.isActive) {
       _showApprovalRequiredDialog(context);
       return;
    }
    setState(() => _isLoading = true);
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
        imageBase64: _imageBase64,
      );
      if (vehicle != null && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApprovalRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approval Pending'),
        content: const Text('Your account is currently being reviewed. You can list vehicles once an admin approves your profile.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: primaryOrange)))],
      ),
    );
  }
}