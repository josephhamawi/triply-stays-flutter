import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Service for uploading images to Firebase Storage
class ImageUploadService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  ImageUploadService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  /// Pick multiple images from gallery
  /// Returns list of XFile or empty list if cancelled
  Future<List<XFile>> pickImages({int maxImages = 10}) async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );

    // Limit to maxImages
    if (images.length > maxImages) {
      return images.take(maxImages).toList();
    }
    return images;
  }

  /// Pick a single image from gallery
  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
  }

  /// Pick image from camera
  Future<XFile?> takePhoto() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
  }

  /// Upload a single image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadImage({
    required String listingId,
    required XFile image,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
    final ref = _storage.ref().child('listings/$listingId/$fileName');

    final File file = File(image.path);
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/${path.extension(image.path).replaceFirst('.', '')}',
      ),
    );

    // Track upload progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    // Wait for upload to complete
    await uploadTask;

    // Get download URL
    return await ref.getDownloadURL();
  }

  /// Upload multiple images for a listing
  /// Returns list of download URLs
  Future<List<String>> uploadListingImages({
    required String listingId,
    required List<XFile> images,
    void Function(int current, int total, double progress)? onProgress,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final url = await uploadImage(
        listingId: listingId,
        image: images[i],
        onProgress: (progress) {
          onProgress?.call(i + 1, images.length, progress);
        },
      );
      urls.add(url);
    }

    return urls;
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  /// Delete all images for a listing
  Future<void> deleteListingImages(String listingId) async {
    try {
      final ref = _storage.ref().child('listings/$listingId');
      final ListResult result = await ref.listAll();

      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Error deleting listing images: $e');
    }
  }

  /// Upload a profile photo for a user
  /// Returns the download URL
  Future<String> uploadProfilePhoto({
    required String userId,
    required XFile image,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
    final ref = _storage.ref().child('users/$userId/profile/$fileName');

    final File file = File(image.path);
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/${path.extension(image.path).replaceFirst('.', '')}',
      ),
    );

    // Track upload progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    // Wait for upload to complete
    await uploadTask;

    // Get download URL
    return await ref.getDownloadURL();
  }

  /// Delete profile photo for a user
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile');
      final ListResult result = await ref.listAll();

      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Error deleting profile photo: $e');
    }
  }
}
