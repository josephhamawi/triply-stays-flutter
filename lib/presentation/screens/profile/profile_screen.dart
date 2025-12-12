import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../domain/entities/user_verifications.dart';
import '../../../data/services/image_upload_service.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/guest_prompt_dialog.dart';
import 'host_pro_screen.dart';
import 'login_security_screen.dart';
import 'my_listings_screen.dart';
import 'verifications_screen.dart';

/// User profile screen with inline editing
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageUploadService = ImageUploadService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _hasWhatsApp = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    if (!_initialized) {
      final user = ref.read(authNotifierProvider).user;
      _firstNameController.text = user?.firstName ?? '';
      _lastNameController.text = user?.lastName ?? '';
      _phoneController.text = user?.phoneNumber ?? '';
      _hasWhatsApp = user?.hasWhatsApp ?? false;
      _initialized = true;
    }
  }

  void _enableEditing() {
    final user = ref.read(authNotifierProvider).user;
    setState(() {
      _firstNameController.text = user?.firstName ?? '';
      _lastNameController.text = user?.lastName ?? '';
      _phoneController.text = user?.phoneNumber ?? '';
      _hasWhatsApp = user?.hasWhatsApp ?? false;
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    final user = ref.read(authNotifierProvider).user;
    setState(() {
      _firstNameController.text = user?.firstName ?? '';
      _lastNameController.text = user?.lastName ?? '';
      _phoneController.text = user?.phoneNumber ?? '';
      _hasWhatsApp = user?.hasWhatsApp ?? false;
      _isEditing = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      hasWhatsApp: _hasWhatsApp,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (success) {
        _isEditing = false;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
            ],
          ),
          backgroundColor: success ? Colors.green : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showPhotoOptions() {
    final user = ref.read(authNotifierProvider).user;
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryOrange),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(fromCamera: false);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryOrange),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(fromCamera: true);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final image = fromCamera
          ? await _imageUploadService.takePhoto()
          : await _imageUploadService.pickImage();

      if (image == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final photoUrl = await _imageUploadService.uploadProfilePhoto(
        userId: user.id,
        image: image,
      );

      final success = await ref.read(authNotifierProvider.notifier).updateProfile(
        photoUrl: photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Profile photo updated' : 'Failed to update profile photo'),
            backgroundColor: success ? Colors.green : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploadingPhoto = true);

    try {
      await _imageUploadService.deleteProfilePhoto(user.id);
      final success = await ref.read(authNotifierProvider.notifier).updateProfile(
        photoUrl: '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Profile photo removed' : 'Failed to remove profile photo'),
            backgroundColor: success ? Colors.green : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(isGuestProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Show guest profile screen
    if (isGuest) {
      return _buildGuestProfileScreen(context);
    }

    _initializeControllers();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // Profile header with avatar and edit button
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryOrange,
                      AppColors.primaryOrange.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Edit/Save/Cancel buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isEditing) ...[
                              TextButton(
                                onPressed: _isSaving ? null : _cancelEditing,
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryOrange,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Save'),
                              ),
                            ] else
                              ElevatedButton.icon(
                                onPressed: _enableEditing,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Avatar with edit overlay
                        GestureDetector(
                          onTap: _isEditing && !_isUploadingPhoto ? _showPhotoOptions : null,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _isUploadingPhoto
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primaryOrange,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: user.photoUrl!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              placeholder: (context, url) => _buildAvatarInitial(user),
                                              errorWidget: (context, url, error) => _buildAvatarInitial(user),
                                            )
                                          : _buildAvatarInitial(user),
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name display or editable fields
                        if (_isEditing) ...[
                          // Editable name fields
                          Row(
                            children: [
                              Expanded(
                                child: _buildEditableField(
                                  controller: _firstNameController,
                                  hint: 'First Name',
                                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildEditableField(
                                  controller: _lastNameController,
                                  hint: 'Last Name',
                                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            user?.fullName ?? user?.displayName ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTrustBadge(user?.verifications ?? const UserVerifications()),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Contact info section (editable when in edit mode)
            if (_isEditing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            hintText: 'Enter with country code',
                            hintStyle: TextStyle(color: AppColors.textLight),
                            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // WhatsApp toggle
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.message, color: Colors.green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WhatsApp Available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Allow contact via WhatsApp',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _hasWhatsApp,
                              onChanged: (value) => setState(() => _hasWhatsApp = value),
                              activeColor: AppColors.primaryOrange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Menu items
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSection('Account', [
                    _MenuItem(
                      icon: Icons.favorite_outline,
                      title: 'Saved Listings',
                      onTap: () => context.push('/favorites'),
                    ),
                    _MenuItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Verifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VerificationsScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.security_outlined,
                      title: 'Login & Security',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginSecurityScreen()),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Hosting', [
                    _MenuItem(
                      icon: Icons.home_work_outlined,
                      title: 'My Listings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyListingsScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.star_outline,
                      title: 'HostPro',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HostProScreen()),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Support', [
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () => _openUrl('https://triplystays.com/#/help'),
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _openUrl('https://triplystays.com/#/privacy'),
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () => _openUrl('https://triplystays.com/#/terms'),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline,
                      title: 'About Triply Stays',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSignOutButton(context, ref),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        errorStyle: const TextStyle(color: Colors.yellow),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Triply Stays'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A FREE vacation rental marketplace connecting hosts and travelers directly.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No booking fees. No commissions. Just direct connections.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version ${packageInfo.version} (${packageInfo.buildNumber})',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitial(dynamic user) {
    final initial = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : user?.displayName?.isNotEmpty == true
            ? user!.displayName![0].toUpperCase()
            : user?.email?.isNotEmpty == true
                ? user!.email[0].toUpperCase()
                : '?';

    return Container(
      width: 100,
      height: 100,
      color: Colors.white,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(UserVerifications verifications) {
    final trustLevel = verifications.trustLevel;
    final verifiedCount = verifications.verifiedCount;

    IconData icon;
    switch (trustLevel) {
      case TrustLevel.trusted:
        icon = Icons.verified;
        break;
      case TrustLevel.verified:
        icon = Icons.check_circle;
        break;
      case TrustLevel.basic:
        icon = Icons.check;
        break;
      case TrustLevel.newUser:
        icon = Icons.person_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            verifiedCount > 0 ? '${trustLevel.name} ($verifiedCount/3)' : 'New User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.textSecondary),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.error),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 16, color: AppColors.error, fontWeight: FontWeight.w500),
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            // Set flag to prevent auto-biometric trigger on sign-in screen
            await BiometricService().setJustSignedOut(true);
            await ref.read(authNotifierProvider.notifier).signOut();
          }
        },
      ),
    );
  }

  Widget _buildGuestProfileScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Guest profile header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryOrange,
                    AppColors.primaryOrange.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Guest avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 50,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Guest User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browsing as guest',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Sign up button
                      ElevatedButton(
                        onPressed: () => GuestPromptDialog.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Up to Unlock All Features',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Benefits of signing up
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create an account to:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitItem(Icons.visibility, 'View listing details'),
                    _buildBenefitItem(Icons.favorite_outline, 'Save favorite properties'),
                    _buildBenefitItem(Icons.chat_bubble_outline, 'Message property owners'),
                    _buildBenefitItem(Icons.home_work_outlined, 'List your own property'),
                    _buildBenefitItem(Icons.verified_user_outlined, 'Get verified status'),
                  ],
                ),
              ),
            ),
          ),

          // Support section (accessible to guests)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('Support', [
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () => _openUrl('https://triplystays.com/#/help'),
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _openUrl('https://triplystays.com/#/privacy'),
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _openUrl('https://triplystays.com/#/terms'),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About Triply Stays',
                    onTap: () => _showAboutDialog(context),
                  ),
                ]),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
