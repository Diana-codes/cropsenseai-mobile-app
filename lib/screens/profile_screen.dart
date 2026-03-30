import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/local_profile_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = LocalProfileService();
  final _auth = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final userName = _profile?['full_name'] ?? 'Guest';
    final phone = _profile?['phone'] ?? '';
    final district = _profile?['district'] ?? '';
    final province = _profile?['province'] ?? '';
    final landSize = _profile?['land_size'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          district.isNotEmpty
                              ? '$district ${landSize > 0 ? '• $landSize hectares' : ''}'
                              : 'Location not set',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    if (phone.isNotEmpty) ...[
                      _buildProfileItem(Icons.phone, phone),
                      const SizedBox(height: 12),
                    ],
                    _buildProfileItem(Icons.verified_user_outlined, t.tr('accountVerified')),
                    const SizedBox(height: 12),
                    if (district.isNotEmpty && province.isNotEmpty)
                      _buildProfileItem(
                        Icons.location_city,
                        '$district, $province',
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(profile: _profile),
                            ),
                          );
                          if (result == true) {
                            _loadProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.edit),
                        label: Text(
                          t.tr('updateInformation'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.tr('settings'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                Icons.notifications_outlined,
                t.tr('notifications'),
                true,
              ),
              _buildSettingItem(
                Icons.language,
                t.tr('language'),
                false,
                onTap: () => _showLanguageDialog(context, t),
              ),
              _buildSettingItem(Icons.security_outlined, t.tr('security'), false,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(t.tr('accountSecurity')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.tr('accountProtected')),
                          const SizedBox(height: 12),
                          Text('🔒  ${t.tr('encryptedStorage')}'),
                          const SizedBox(height: 6),
                          Text('🔑  ${t.tr('secureTokens')}'),
                          const SizedBox(height: 6),
                          Text('📵  ${t.tr('autoExpiry')}'),
                          const SizedBox(height: 16),
                          Text(
                            t.tr('changePasswordHint'),
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.tr('sharedDeviceWarning'),
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t.tr('gotIt')),
                        ),
                      ],
                    ),
                  )),
              _buildSettingItem(Icons.help_outline, t.tr('help'), false,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.tr('helpSupport'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text(t.tr('howToUse'),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            t.tr('howToUseSteps'),
                            style: const TextStyle(fontSize: 13, height: 1.6),
                          ),
                          const SizedBox(height: 16),
                          Text(t.tr('contactSupport'),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text(
                            '📧  support@cropsenseai.rw\n'
                            '🌐  www.cropsenseai.rw',
                            style: TextStyle(fontSize: 13, height: 1.6),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(t.tr('close')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await _auth.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text(
                    t.tr('logOut'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Version 1.0.0 • BUILD 29032025',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.tr('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: AppSettings.localeNotifier.value.languageCode,
                onChanged: (value) {
                  AppSettings.setLocale(const Locale('en'));
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Kinyarwanda'),
              leading: Radio<String>(
                value: 'rw',
                groupValue: AppSettings.localeNotifier.value.languageCode,
                onChanged: (value) {
                  AppSettings.setLocale(const Locale('rw'));
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, bool hasSwitch, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (hasSwitch)
            Switch(
              value: AppSettings.notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  AppSettings.setNotifications(value);
                });
              },
              activeColor: AppColors.primary,
            )
          else
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      ),
    );
  }
}
