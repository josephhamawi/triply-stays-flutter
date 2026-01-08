import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/image_upload_service.dart';
import '../../../domain/entities/listing.dart';
import '../auth/auth_provider.dart';
import 'listings_provider.dart';

/// Represents an image that can be either a local file (XFile) or a network URL
class ListingImage {
  final XFile? file;
  final String? url;

  ListingImage.file(this.file) : url = null;
  ListingImage.url(this.url) : file = null;

  bool get isFile => file != null;
  bool get isUrl => url != null;

  String get displayPath => file?.path ?? url ?? '';
}

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
  final List<String> existingImageUrls;  // For edit mode - existing images from server

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
    this.existingImageUrls = const [],
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
    List<String>? existingImageUrls,
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
      existingImageUrls: existingImageUrls ?? this.existingImageUrls,
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

  bool get hasImages => selectedImages.isNotEmpty || uploadedImageUrls.isNotEmpty || existingImageUrls.isNotEmpty;
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

  /// Initialize form data with existing listing for edit mode
  void initializeForEdit(Listing listing) {
    state = state.copyWith(
      formData: AddListingFormData(
        title: listing.title,
        description: listing.description,
        category: listing.category ?? '',
        listingViews: List<String>.from(listing.listingViews),
        country: listing.country,
        city: listing.city,
        location: listing.location,
        price: listing.price,
        weekendPrice: listing.weekendPrice,
        bedrooms: listing.bedrooms,
        bathrooms: listing.bathrooms,
        livingRooms: listing.livingRooms,
        beds: listing.beds,
        maxGuests: listing.maxGuests,
        amenities: List<String>.from(listing.amenities),
        rules: listing.rules,
        selectedImages: const [],
        uploadedImageUrls: const [],
        existingImageUrls: List<String>.from(listing.images),
      ),
    );
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

  /// Get total image count (existing + new)
  int get totalImageCount => state.formData.existingImageUrls.length + state.formData.selectedImages.length;

  Future<void> pickImages() async {
    final remainingSlots = 10 - totalImageCount;
    if (remainingSlots <= 0) return;

    final images = await _imageUploadService.pickImages(maxImages: remainingSlots);
    if (images.isNotEmpty) {
      final currentImages = List<XFile>.from(state.formData.selectedImages);
      currentImages.addAll(images.take(remainingSlots));
      updateFormData((data) => data.copyWith(selectedImages: currentImages));
    }
  }

  Future<void> takePhoto() async {
    if (totalImageCount >= 10) return;

    final image = await _imageUploadService.takePhoto();
    if (image != null) {
      final currentImages = List<XFile>.from(state.formData.selectedImages);
      currentImages.add(image);
      updateFormData((data) => data.copyWith(selectedImages: currentImages));
    }
  }

  /// Remove image at index (handles both existing and new images)
  void removeImage(int index) {
    final existingCount = state.formData.existingImageUrls.length;

    if (index < existingCount) {
      // Remove from existing images
      final existingImages = List<String>.from(state.formData.existingImageUrls);
      existingImages.removeAt(index);
      updateFormData((data) => data.copyWith(existingImageUrls: existingImages));
    } else {
      // Remove from new images
      final newIndex = index - existingCount;
      final currentImages = List<XFile>.from(state.formData.selectedImages);
      if (newIndex < currentImages.length) {
        currentImages.removeAt(newIndex);
        updateFormData((data) => data.copyWith(selectedImages: currentImages));
      }
    }
  }

  /// Reorder images (for now only supports moving new images to cover position)
  void reorderImages(int oldIndex, int newIndex) {
    final existingCount = state.formData.existingImageUrls.length;

    // If moving within existing images
    if (oldIndex < existingCount && newIndex < existingCount) {
      final existingImages = List<String>.from(state.formData.existingImageUrls);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final image = existingImages.removeAt(oldIndex);
      existingImages.insert(newIndex, image);
      updateFormData((data) => data.copyWith(existingImageUrls: existingImages));
    }
    // If moving within new images only
    else if (oldIndex >= existingCount && newIndex >= existingCount) {
      final adjustedOld = oldIndex - existingCount;
      var adjustedNew = newIndex - existingCount;
      final currentImages = List<XFile>.from(state.formData.selectedImages);
      if (adjustedOld < adjustedNew) {
        adjustedNew -= 1;
      }
      final image = currentImages.removeAt(adjustedOld);
      currentImages.insert(adjustedNew, image);
      updateFormData((data) => data.copyWith(selectedImages: currentImages));
    }
    // If moving a new image to cover (position 0)
    else if (oldIndex >= existingCount && newIndex == 0) {
      // Move new image to front of new images, and move first existing to first position of new order
      final existingImages = List<String>.from(state.formData.existingImageUrls);
      final currentImages = List<XFile>.from(state.formData.selectedImages);
      final adjustedOld = oldIndex - existingCount;

      // Remove from new and add existing first to end of existing
      final newImage = currentImages.removeAt(adjustedOld);
      currentImages.insert(0, newImage);

      // For simplicity, just reorder within new images to bring selected to front
      updateFormData((data) => data.copyWith(
        selectedImages: currentImages,
        existingImageUrls: existingImages,
      ));
    }
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

  Future<bool> submitListing({bool isEditMode = false, String? listingId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authNotifierProvider);
      final user = authState.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You must be logged in to ${isEditMode ? 'update' : 'create'} a listing',
        );
        return false;
      }

      final repository = _ref.read(listingRepositoryProvider);
      final formData = state.formData;

      if (isEditMode && listingId != null) {
        // Edit mode: Update existing listing
        List<String> finalImageUrls = List<String>.from(formData.existingImageUrls);

        // Upload new images if any
        if (formData.selectedImages.isNotEmpty) {
          state = state.copyWith(
            isUploading: true,
            totalUploads: formData.selectedImages.length,
          );

          final newImageUrls = await _imageUploadService.uploadListingImages(
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

          // Append new images to existing ones
          finalImageUrls.addAll(newImageUrls);
        }

        // Update the listing
        final updatedListing = Listing(
          id: listingId,
          title: formData.title,
          description: formData.description,
          price: formData.price,
          weekendPrice: formData.weekendPrice,
          city: formData.city,
          country: formData.country,
          images: finalImageUrls,
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
          createdAt: DateTime.now(), // Will be ignored on update
        );

        await repository.updateListing(updatedListing);

        state = state.copyWith(
          isLoading: false,
          isUploading: false,
          createdListingId: listingId,
        );

        return true;
      } else {
        // Create mode: Create new listing
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
        final newListingId = await repository.createListing(listing);

        // Upload images
        if (formData.selectedImages.isNotEmpty) {
          state = state.copyWith(
            isUploading: true,
            totalUploads: formData.selectedImages.length,
          );

          final imageUrls = await _imageUploadService.uploadListingImages(
            listingId: newListingId,
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
            id: newListingId,
            images: imageUrls,
          );
          await repository.updateListing(updatedListing);
        }

        state = state.copyWith(
          isLoading: false,
          isUploading: false,
          createdListingId: newListingId,
        );

        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isUploading: false,
        errorMessage: 'Failed to ${isEditMode ? 'update' : 'create'} listing: ${e.toString()}',
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
