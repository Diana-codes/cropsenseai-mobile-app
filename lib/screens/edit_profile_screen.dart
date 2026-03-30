import 'package:flutter/material.dart';
import '../data/rwanda_locations.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import '../services/local_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = LocalProfileService();
  final _auth = AuthService();
  bool _isLoading = false;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _landSizeController;
  late TextEditingController _soilTypeController;

  String? _selectedProvince;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile?['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.profile?['phone'] ?? '');
    _locationController = TextEditingController(text: widget.profile?['location'] ?? '');
    _landSizeController = TextEditingController(
      text: widget.profile?['land_size']?.toString() ?? '',
    );
    _soilTypeController = TextEditingController(text: widget.profile?['soil_type'] ?? '');
    _selectedProvince = widget.profile?['province'];
    _selectedDistrict = widget.profile?['district'];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _landSizeController.dispose();
    _soilTypeController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    try {
      await _profileService.updateProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        district: _selectedDistrict,
        province: _selectedProvince,
        landSize: double.tryParse(_landSizeController.text),
        soilType: _soilTypeController.text.trim(),
      );

      // Best-effort sync to backend (only if logged in). UI still works offline.
      await _auth.updateProfile({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'district': _selectedDistrict,
        'province': _selectedProvince,
        'land_size': double.tryParse(_landSizeController.text),
        'soil_type': _soilTypeController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.tr('profileUpdated')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.tr('updateFailed')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.tr('editProfile'),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: t.tr('fullName'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t.tr('enterFullName');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: t.tr('phoneNumber'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: t.tr('province'),
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: RwandaLocations.getProvinces().map((province) {
                    return DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: InputDecoration(
                    labelText: t.tr('district'),
                    prefixIcon: const Icon(Icons.place_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _selectedProvince != null
                      ? RwandaLocations.getDistricts(_selectedProvince!)
                          .map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district),
                          );
                        }).toList()
                      : [],
                  onChanged: _selectedProvince != null
                      ? (value) {
                          setState(() => _selectedDistrict = value);
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: t.tr('specificLocation'),
                    prefixIcon: const Icon(Icons.my_location),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landSizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.tr('landSizeHectares'),
                    prefixIcon: const Icon(Icons.landscape_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _soilTypeController,
                  decoration: InputDecoration(
                    labelText: t.tr('soilType'),
                    prefixIcon: const Icon(Icons.terrain),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          t.tr('updateProfile'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
