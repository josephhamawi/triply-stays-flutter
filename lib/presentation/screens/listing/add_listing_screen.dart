import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
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
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
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
          _buildSectionTitle('View'),
          const SizedBox(height: 8),
          viewsAsync.when(
            data: (views) => _buildDropdown(
              value: state.formData.view.isEmpty ? null : state.formData.view,
              hint: 'Select the main view',
              items: views,
              onChanged: (value) => notifier.updateFormData(
                (data) => data.copyWith(view: value ?? ''),
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Failed to load views'),
          ),
          const SizedBox(height: 100),
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
  late final TextEditingController _cityController;
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
    _cityController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    // Initialize controllers only once with existing data
    if (!_initialized) {
      _cityController.text = state.formData.city;
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
              _cityController.clear();
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('City'),
          const SizedBox(height: 8),
          TextField(
            controller: _cityController,
            decoration: _inputDecoration('Enter city name'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(city: value),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Google Maps Link (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: _inputDecoration('Paste Google Maps URL'),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            onChanged: (value) => notifier.updateFormData(
              (data) => data.copyWith(location: value.isEmpty ? null : value),
            ),
          ),
          const SizedBox(height: 100),
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    // Initialize controller only once with existing data
    if (!_initialized) {
      if (state.formData.price > 0) {
        _priceController.text = state.formData.price.toStringAsFixed(0);
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
          const SizedBox(height: 100),
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
          const SizedBox(height: 100),
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
          const SizedBox(height: 16),
          if (state.formData.selectedImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.formData.selectedImages.length,
              itemBuilder: (context, index) {
                final image = state.formData.selectedImages[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => notifier.removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
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
                );
              },
            ),
          const SizedBox(height: 100),
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
          const SizedBox(height: 100),
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
            _buildReviewRow('View', formData.view),
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
          const SizedBox(height: 100),
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
        hint: Text(hint),
        isExpanded: true,
        items: items.asMap().entries.map((entry) {
          final label = itemLabels != null ? itemLabels[entry.key] : entry.value;
          return DropdownMenuItem(
            value: entry.value,
            child: Text(label),
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
