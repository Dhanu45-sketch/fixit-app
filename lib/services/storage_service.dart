import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  // Pick multiple images (for certificates)
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.length > maxImages) {
        return images.take(maxImages).map((xFile) => File(xFile.path)).toList();
      }

      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('profile_images/$userId/$fileName');

      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) {
          onProgress(progress);
        }
      });

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  // Upload certificate
  Future<String?> uploadCertificate({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName = 'cert_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('certificates/$userId/$fileName');

      final UploadTask uploadTask = storageRef.putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) {
          onProgress(progress);
        }
      });

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading certificate: $e');
      return null;
    }
  }

  // Upload multiple certificates
  Future<List<String>> uploadMultipleCertificates({
    required String userId,
    required List<File> imageFiles,
    Function(int current, int total)? onProgress,
  }) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      if (onProgress != null) {
        onProgress(i + 1, imageFiles.length);
      }

      final String? url = await uploadCertificate(
        userId: userId,
        imageFile: imageFiles[i],
      );

      if (url != null) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }

  // Delete image from storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      await deleteImage(url);
    }
  }
}