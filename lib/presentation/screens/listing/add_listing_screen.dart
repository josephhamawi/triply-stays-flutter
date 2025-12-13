import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/listings/add_listing_provider.dart';
import '../../providers/listings/listings_provider.dart';

/// Screen for adding a new listing
class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final PageController _pageController = PageController();

  final List<String> _stepTitles = [
    'Basic Info',
    'Location',
    'Details',
    'Amenities',
    'Photos',
    'House Rules',
    'Review',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildEmailVerificationRequired(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Host'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 50,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Email Verification Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'To become a host and list your property, you need to verify your email address first.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/profile');
                    // Navigate to Login & Security from profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Profile Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Check if email is verified - required to host
    if (user == null || !user.emailVerified) {
      return _buildEmailVerificationRequired(context);
    }

    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    ref.listen<AddListingState>(addListingProvider, (previous, next) {
      if (next.currentStep != previous?.currentStep) {
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (state.currentStep > 0) {
          notifier.previousStep();
        } else {
          final shouldPop = await _showExitConfirmation(context);
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(_stepTitles[state.currentStep]),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _showExitConfirmation(context);
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Column(
          children: [
            _buildProgressIndicator(state),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _BasicInfoStep(),
                  _LocationStep(),
                  _DetailsStep(),
                  _AmenitiesStep(),
                  _PhotosStep(),
                  _RulesStep(),
                  _ReviewStep(),
                ],
              ),
            ),
            _buildBottomNavigation(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AddListingState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(AddListingState.totalSteps, (index) {
          final isCompleted = index < state.currentStep;
          final isCurrent = index == state.currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primaryOrange
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigation(AddListingState state, AddListingNotifier notifier) {
    final isLastStep = state.currentStep == AddListingState.totalSteps - 1;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            TextButton(
              onPressed: notifier.previousStep,
              child: const Text('Back'),
            ),
          const Spacer(),
          if (state.isLoading || state.isUploading)
            _buildLoadingButton(state)
          else
            ElevatedButton(
              onPressed: state.canGoNext
                  ? () {
                      if (isLastStep) {
                        _submitListing(notifier);
                      } else {
                        notifier.nextStep();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isLastStep ? 'Submit Listing' : 'Next'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingButton(AddListingState state) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(state.isUploading
              ? 'Uploading ${state.currentUploadIndex}/${state.totalUploads}'
              : 'Creating...'),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Listing?'),
        content: const Text(
          'Are you sure you want to leave? Your listing will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submitListing(AddListingNotifier notifier) async {
    final success = await notifier.submitListing();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing submitted for review!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      final errorMessage = ref.read(addListingProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to submit listing'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Step 1: Basic Info
class _BasicInfoStep extends ConsumerStatefulWidget {
  const _BasicInfoStep();

  @override
  ConsumerState<_BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends ConsumerState<_BasicInfoStep> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);
    final viewsAsync = ref.watch(viewsProvider);

    // Initialize controllers only once with existing data
    if (!_initialized) {
      _titleController.text = state.formData.title;
      _descriptionController.text = state.formData.description;
      _initialized = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Title'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration('Give your property a catchy title'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            maxLength: 100,
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(title: value),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: _inputDecoration('Describe your property in detail'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            maxLines: 5,
            maxLength: 2000,
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(description: value),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Category'),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => _buildDropdown(
              value: state.formData.category.isEmpty ? null : state.formData.category,
              hint: 'Select property type',
              items: categories,
              onChanged: (value) => notifier.updateFormData(
                (data) => data.copyWith(category: value ?? ''),
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load categories'),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Views'),
          const SizedBox(height: 4),
          Text(
            'Select all views that apply',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          viewsAsync.when(
            data: (views) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: views.map((view) {
                final isSelected = state.formData.listingViews.contains(view);
                return FilterChip(
                  label: Text('$view View'),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryOrange : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  selected: isSelected,
                  onSelected: (_) => notifier.toggleView(view),
                  selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryOrange,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryOrange
                          : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load views'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 2: Location
class _LocationStep extends ConsumerStatefulWidget {
  const _LocationStep();

  @override
  ConsumerState<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<_LocationStep> {
  late final TextEditingController _locationController;
  bool _initialized = false;

  static const List<Map<String, String>> _countries = [
    {'code': 'LB', 'name': 'Lebanon'},
    {'code': 'AE', 'name': 'UAE'},
    {'code': 'SA', 'name': 'Saudi Arabia'},
    {'code': 'EG', 'name': 'Egypt'},
    {'code': 'JO', 'name': 'Jordan'},
    {'code': 'TR', 'name': 'Turkey'},
    {'code': 'CY', 'name': 'Cyprus'},
    {'code': 'GR', 'name': 'Greece'},
  ];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);
    final citiesAsync = ref.watch(citiesProvider(state.formData.country));

    // Initialize controller only once with existing data
    if (!_initialized) {
      _locationController.text = state.formData.location ?? '';
      _initialized = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Country'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: state.formData.country,
            hint: 'Select country',
            items: _countries.map((c) => c['code']!).toList(),
            itemLabels: _countries.map((c) => c['name']!).toList(),
            onChanged: (value) {
              notifier.updateFormData(
                (data) => data.copyWith(country: value ?? 'LB', city: ''),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('City'),
          const SizedBox(height: 8),
          citiesAsync.when(
            data: (cities) => cities.isNotEmpty
                ? _buildDropdown(
                    value: state.formData.city.isEmpty ? null : state.formData.city,
                    hint: 'Select city',
                    items: cities,
                    onChanged: (value) => notifier.updateFormData(
                      (data) => data.copyWith(city: value ?? ''),
                    ),
                  )
                : TextField(
                    decoration: _inputDecoration('Enter city name'),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    onChanged: (value) => notifier.updateFormData(
                      (data) => data.copyWith(city: value),
                    ),
                  ),
            loading: () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading cities...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            ),
            error: (_, __) => TextField(
              decoration: _inputDecoration('Enter city name'),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              onChanged: (value) => notifier.updateFormData(
                (data) => data.copyWith(city: value),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Google Maps Link (Optional)'),
          const SizedBox(height: 4),
          Text(
            'Copy your listing location link from Google Maps. Find your location, click "Share", and paste the link here.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: _inputDecoration('https://maps.app.goo.gl/... or https://www.google.com/maps?q=...'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(location: value.isEmpty ? null : value),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 3: Details
class _DetailsStep extends ConsumerStatefulWidget {
  const _DetailsStep();

  @override
  ConsumerState<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<_DetailsStep> {
  late final TextEditingController _priceController;
  late final TextEditingController _weekendPriceController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _weekendPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _weekendPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    // Initialize controllers only once with existing data
    if (!_initialized) {
      if (state.formData.price > 0) {
        _priceController.text = state.formData.price.toStringAsFixed(0);
      }
      if (state.formData.weekendPrice != null && state.formData.weekendPrice! > 0) {
        _weekendPriceController.text = state.formData.weekendPrice!.toStringAsFixed(0);
      }
      _initialized = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Price per Night (USD)'),
          const SizedBox(height: 8),
          TextField(
            controller: _priceController,
            decoration: _inputDecoration('\$0'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            keyboardType: TextInputType.number,
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(price: double.tryParse(value) ?? 0),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Weekend Price per Night (USD)'),
          const SizedBox(height: 4),
          Text(
            'Optional - Set a different price for Friday & Saturday nights',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weekendPriceController,
            decoration: _inputDecoration('\$0 (Optional)'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            keyboardType: TextInputType.number,
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(
                weekendPrice: value.isEmpty ? null : double.tryParse(value),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildCounterRow(
            'Bedrooms',
            state.formData.bedrooms,
            (value) => notifier.updateFormData(
              (data) => data.copyWith(bedrooms: value),
            ),
          ),
          _buildCounterRow(
            'Bathrooms',
            state.formData.bathrooms,
            (value) => notifier.updateFormData(
              (data) => data.copyWith(bathrooms: value),
            ),
          ),
          _buildCounterRow(
            'Living Rooms',
            state.formData.livingRooms,
            (value) => notifier.updateFormData(
              (data) => data.copyWith(livingRooms: value),
            ),
            minValue: 0,
          ),
          _buildCounterRow(
            'Beds',
            state.formData.beds,
            (value) => notifier.updateFormData(
              (data) => data.copyWith(beds: value),
            ),
          ),
          _buildCounterRow(
            'Max Guests',
            state.formData.maxGuests,
            (value) => notifier.updateFormData(
              (data) => data.copyWith(maxGuests: value),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 4: Amenities
class _AmenitiesStep extends ConsumerWidget {
  const _AmenitiesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);
    final amenitiesAsync = ref.watch(amenitiesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Select Amenities'),
          const SizedBox(height: 8),
          Text(
            'Choose all the amenities your property offers',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          amenitiesAsync.when(
            data: (amenities) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) {
                final isSelected = state.formData.amenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryOrange : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  selected: isSelected,
                  onSelected: (_) => notifier.toggleAmenity(amenity),
                  selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryOrange,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryOrange
                          : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load amenities'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 5: Photos
class _PhotosStep extends ConsumerWidget {
  const _PhotosStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Add Photos'),
          const SizedBox(height: 8),
          Text(
            'Add up to 10 photos of your property. The first photo will be the cover image.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: notifier.pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primaryOrange),
                    foregroundColor: AppColors.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: notifier.takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primaryOrange),
                    foregroundColor: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${state.formData.selectedImages.length}/10 photos selected',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (state.formData.selectedImages.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tap a photo to set it as cover. Tap × to remove.',
              style: TextStyle(color: AppColors.primaryOrange, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          if (state.formData.selectedImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: state.formData.selectedImages.length,
              itemBuilder: (context, index) {
                final image = state.formData.selectedImages[index];
                final isCover = index == 0;
                return GestureDetector(
                  onTap: () {
                    // Move tapped image to first position (make it cover)
                    if (index != 0) {
                      notifier.reorderImages(index, 0);
                    }
                  },
                  child: Container(
                    key: ValueKey(image.path),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isCover
                          ? Border.all(color: AppColors.primaryOrange, width: 3)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(isCover ? 9 : 12),
                          child: Image.file(
                            File(image.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Cover badge
                        if (isCover)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Cover',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Photo number badge
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Delete button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => notifier.removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 6: House Rules
class _RulesStep extends ConsumerStatefulWidget {
  const _RulesStep();

  @override
  ConsumerState<_RulesStep> createState() => _RulesStepState();
}

class _RulesStepState extends ConsumerState<_RulesStep> {
  late final TextEditingController _rulesController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _rulesController = TextEditingController();
  }

  @override
  void dispose() {
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    // Initialize controller only once with existing data
    if (!_initialized) {
      _rulesController.text = state.formData.rules ?? '';
      _initialized = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('House Rules (Optional)'),
          const SizedBox(height: 8),
          Text(
            'Set expectations for your guests. Include check-in/check-out times, pet policy, smoking rules, etc.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rulesController,
            decoration: _inputDecoration(
              'e.g., No smoking, No pets, Check-in after 3 PM...',
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            maxLines: 10,
            maxLength: 2000,
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(rules: value.isEmpty ? null : value),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Step 7: Review
class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addListingProvider);
    final formData = state.formData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Review Your Listing'),
          const SizedBox(height: 8),
          Text(
            'Please review the information below before submitting.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildReviewCard([
            _buildReviewRow('Title', formData.title),
            _buildReviewRow('Category', formData.category),
            _buildReviewRow(
              'Views',
              formData.listingViews.isEmpty
                  ? 'None selected'
                  : formData.listingViews.map((v) => '$v View').join(', '),
            ),
          ]),
          const SizedBox(height: 16),
          _buildReviewCard([
            _buildReviewRow('City', formData.city),
            _buildReviewRow('Country', formData.country),
            if (formData.location != null)
              _buildReviewRow('Maps Link', 'Provided'),
          ]),
          const SizedBox(height: 16),
          _buildReviewCard([
            _buildReviewRow('Price', '\$${formData.price.toStringAsFixed(0)}/night'),
            if (formData.weekendPrice != null)
              _buildReviewRow('Weekend Price', '\$${formData.weekendPrice!.toStringAsFixed(0)}/night'),
            _buildReviewRow('Bedrooms', formData.bedrooms.toString()),
            _buildReviewRow('Bathrooms', formData.bathrooms.toString()),
            _buildReviewRow('Living Rooms', formData.livingRooms.toString()),
            _buildReviewRow('Beds', formData.beds.toString()),
            _buildReviewRow('Max Guests', formData.maxGuests.toString()),
          ]),
          const SizedBox(height: 16),
          _buildReviewCard([
            _buildReviewRow(
              'Amenities',
              formData.amenities.isEmpty
                  ? 'None selected'
                  : formData.amenities.join(', '),
            ),
          ]),
          const SizedBox(height: 16),
          _buildReviewCard([
            _buildReviewRow(
              'Photos',
              '${formData.selectedImages.length} photos',
            ),
            _buildReviewRow(
              'House Rules',
              formData.rules?.isNotEmpty == true ? 'Provided' : 'None',
            ),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your listing will be reviewed before being published. This usually takes 24-48 hours.',
                    style: TextStyle(color: AppColors.info, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReviewCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (entry) => Column(
                children: [
                  entry.value,
                  if (entry.key < children.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400]),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryOrange),
    ),
  );
}

Widget _buildDropdown({
  required String? value,
  required String hint,
  required List<String> items,
  List<String>? itemLabels,
  required void Function(String?) onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(color: Colors.grey[400]),
        ),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
        items: items.asMap().entries.map((entry) {
          final label = itemLabels != null ? itemLabels[entry.key] : entry.value;
          return DropdownMenuItem(
            value: entry.value,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

Widget _buildCounterRow(
  String label,
  int value,
  void Function(int) onChanged, {
  int minValue = 1,
  int maxValue = 20,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: value > minValue ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: value > minValue ? AppColors.primaryOrange : Colors.grey,
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: value < maxValue ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
              color: value < maxValue ? AppColors.primaryOrange : Colors.grey,
            ),
          ],
        ),
      ],
    ),
  );
}
