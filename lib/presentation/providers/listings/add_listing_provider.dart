import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/image_upload_service.dart';
import '../../../domain/entities/listing.dart';
import '../auth/auth_provider.dart';
import 'listings_provider.dart';

/// Form data state for add listing
class AddListingFormData {
  final String title;
  final String description;
  final String category;
  final List<String> listingViews;  // Multi-select views (sea, mountain, city, etc.)
  final String country;
  final String city;
  final String? location;
  final double price;
  final double? weekendPrice;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final int beds;
  final int maxGuests;
  final List<String> amenities;
  final String? rules;
  final List<XFile> selectedImages;
  final List<String> uploadedImageUrls;

  const AddListingFormData({
    this.title = '',
    this.description = '',
    this.category = '',
    this.listingViews = const [],
    this.country = 'LB',
    this.city = '',
    this.location,
    this.price = 0,
    this.weekendPrice,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.livingRooms = 0,
    this.beds = 1,
    this.maxGuests = 2,
    this.amenities = const [],
    this.rules,
    this.selectedImages = const [],
    this.uploadedImageUrls = const [],
  });

  AddListingFormData copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? listingViews,
    String? country,
    String? city,
    String? location,
    double? price,
    double? weekendPrice,
    int? bedrooms,
    int? bathrooms,
    int? livingRooms,
    int? beds,
    int? maxGuests,
    List<String>? amenities,
    String? rules,
    List<XFile>? selectedImages,
    List<String>? uploadedImageUrls,
  }) {
    return AddListingFormData(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      listingViews: listingViews ?? this.listingViews,
      country: country ?? this.country,
      city: city ?? this.city,
      location: location ?? this.location,
      price: price ?? this.price,
      weekendPrice: weekendPrice ?? this.weekendPrice,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      livingRooms: livingRooms ?? this.livingRooms,
      beds: beds ?? this.beds,
      maxGuests: maxGuests ?? this.maxGuests,
      amenities: amenities ?? this.amenities,
      rules: rules ?? this.rules,
      selectedImages: selectedImages ?? this.selectedImages,
      uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
    );
  }

  bool get isBasicInfoValid =>
      title.isNotEmpty &&
      description.isNotEmpty &&
      category.isNotEmpty &&
      listingViews.isNotEmpty;

  bool get isLocationValid => city.isNotEmpty;

  bool get isDetailsValid =>
      price > 0 &&
      bedrooms > 0 &&
      bathrooms > 0 &&
      beds > 0 &&
      maxGuests > 0;

  bool get hasImages => selectedImages.isNotEmpty || uploadedImageUrls.isNotEmpty;
}

/// State for the add listing screen
class AddListingState {
  final int currentStep;
  final AddListingFormData formData;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;
  final double uploadProgress;
  final int currentUploadIndex;
  final int totalUploads;
  final String? createdListingId;

  const AddListingState({
    this.currentStep = 0,
    this.formData = const AddListingFormData(),
    this.isLoading = false,
    this.isUploading = false,
    this.errorMessage,
    this.uploadProgress = 0,
    this.currentUploadIndex = 0,
    this.totalUploads = 0,
    this.createdListingId,
  });

  AddListingState copyWith({
    int? currentStep,
    AddListingFormData? formData,
    bool? isLoading,
    bool? isUploading,
    String? errorMessage,
    double? uploadProgress,
    int? currentUploadIndex,
    int? totalUploads,
    String? createdListingId,
  }) {
    return AddListingState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      currentUploadIndex: currentUploadIndex ?? this.currentUploadIndex,
      totalUploads: totalUploads ?? this.totalUploads,
      createdListingId: createdListingId ?? this.createdListingId,
    );
  }

  bool get canGoNext {
    switch (currentStep) {
      case 0:
        return formData.isBasicInfoValid;
      case 1:
        return formData.isLocationValid;
      case 2:
        return formData.isDetailsValid;
      case 3:
        return true; // Amenities are optional
      case 4:
        return formData.hasImages;
      case 5:
        return true; // Rules are optional
      default:
        return true;
    }
  }

  static const int totalSteps = 7;
}

/// Notifier for add listing state
class AddListingNotifier extends StateNotifier<AddListingState> {
  final Ref _ref;
  final ImageUploadService _imageUploadService;

  AddListingNotifier(this._ref)
      : _imageUploadService = ImageUploadService(),
        super(const AddListingState());

  void updateFormData(AddListingFormData Function(AddListingFormData) updater) {
    state = state.copyWith(formData: updater(state.formData));
  }

  void nextStep() {
    if (state.currentStep < AddListingState.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < AddListingState.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<void> pickImages() async {
    final images = await _imageUploadService.pickImages(maxImages: 10);
    if (images.isNotEmpty) {
      final currentImages = List<XFile>.from(state.formData.selectedImages);
      final remainingSlots = 10 - currentImages.length;
      currentImages.addAll(images.take(remainingSlots));
      updateFormData((data) => data.copyWith(selectedImages: currentImages));
    }
  }

  Future<void> takePhoto() async {
    if (state.formData.selectedImages.length >= 10) return;

    final image = await _imageUploadService.takePhoto();
    if (image != null) {
      final currentImages = List<XFile>.from(state.formData.selectedImages);
      currentImages.add(image);
      updateFormData((data) => data.copyWith(selectedImages: currentImages));
    }
  }

  void removeImage(int index) {
    final currentImages = List<XFile>.from(state.formData.selectedImages);
    if (index < currentImages.length) {
      currentImages.removeAt(index);
      updateFormData((data) => data.copyWith(selectedImages: currentImages));
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    final currentImages = List<XFile>.from(state.formData.selectedImages);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final image = currentImages.removeAt(oldIndex);
    currentImages.insert(newIndex, image);
    updateFormData((data) => data.copyWith(selectedImages: currentImages));
  }

  void toggleAmenity(String amenity) {
    final currentAmenities = List<String>.from(state.formData.amenities);
    if (currentAmenities.contains(amenity)) {
      currentAmenities.remove(amenity);
    } else {
      currentAmenities.add(amenity);
    }
    updateFormData((data) => data.copyWith(amenities: currentAmenities));
  }

  void toggleView(String view) {
    final currentViews = List<String>.from(state.formData.listingViews);
    if (currentViews.contains(view)) {
      currentViews.remove(view);
    } else {
      currentViews.add(view);
    }
    updateFormData((data) => data.copyWith(listingViews: currentViews));
  }

  Future<bool> submitListing() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authNotifierProvider);
      final user = authState.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You must be logged in to create a listing',
        );
        return false;
      }

      final repository = _ref.read(listingRepositoryProvider);
      final formData = state.formData;

      // Create the listing first to get the ID
      final listing = Listing(
        id: '',
        title: formData.title,
        description: formData.description,
        price: formData.price,
        weekendPrice: formData.weekendPrice,
        city: formData.city,
        country: formData.country,
        images: [],
        hostId: user.id,
        hostName: user.fullName ?? user.displayName,
        hostPhone: user.phoneNumber,
        hostHasWhatsApp: user.hasWhatsApp,
        category: formData.category,
        listingViews: formData.listingViews,
        amenities: formData.amenities,
        rules: formData.rules,
        bedrooms: formData.bedrooms,
        bathrooms: formData.bathrooms,
        livingRooms: formData.livingRooms,
        beds: formData.beds,
        maxGuests: formData.maxGuests,
        location: formData.location,
        createdAt: DateTime.now(),
      );

      // Create the listing to get the ID
      final listingId = await repository.createListing(listing);

      // Upload images
      if (formData.selectedImages.isNotEmpty) {
        state = state.copyWith(
          isUploading: true,
          totalUploads: formData.selectedImages.length,
        );

        final imageUrls = await _imageUploadService.uploadListingImages(
          listingId: listingId,
          images: formData.selectedImages,
          onProgress: (current, total, progress) {
            state = state.copyWith(
              currentUploadIndex: current,
              totalUploads: total,
              uploadProgress: progress,
            );
          },
        );

        // Update listing with image URLs
        final updatedListing = listing.copyWith(
          id: listingId,
          images: imageUrls,
        );
        await repository.updateListing(updatedListing);
      }

      state = state.copyWith(
        isLoading: false,
        isUploading: false,
        createdListingId: listingId,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isUploading: false,
        errorMessage: 'Failed to create listing: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = const AddListingState();
  }
}

/// Provider for add listing state
final addListingProvider =
    StateNotifierProvider.autoDispose<AddListingNotifier, AddListingState>(
        (ref) {
  return AddListingNotifier(ref);
});

/// Provider for image upload service
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});
