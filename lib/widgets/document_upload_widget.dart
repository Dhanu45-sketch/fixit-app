// lib/widgets/document_upload_widget.dart
// FIXED VERSION - Properly uploads to Firebase Storage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';

class DocumentUploadWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onUploadComplete;

  const DocumentUploadWidget({
    Key? key,
    required this.userId,
    this.onUploadComplete,
  }) : super(key: key);

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  final ImagePicker _picker = ImagePicker();

  File? _idCardFront;
  File? _idCardBack;
  File? _certificate;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  String? _idCardFrontUrl;
  String? _idCardBackUrl;
  String? _certificateUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingDocuments();
  }

  // FIX: Load existing documents if already uploaded
  Future<void> _loadExistingDocuments() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('verificationDocuments')
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _idCardFrontUrl = data?['id_card_front'];
          _idCardBackUrl = data?['id_card_back'];
          _certificateUrl = data?['certificate'];
        });
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    }
  }

  Future<void> _pickImage(String documentType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // FIX: Validate file size (max 5MB)
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ File too large. Maximum size is 5MB'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          switch (documentType) {
            case 'id_front':
              _idCardFront = file;
              break;
            case 'id_back':
              _idCardBack = file;
              break;
            case 'certificate':
              _certificate = file;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // FIX: Improved upload with better error handling and progress tracking
  Future<String?> _uploadFile(File file, String documentType) async {
    try {
      setState(() {
        _uploadStatus = 'Uploading ${documentType.replaceAll('_', ' ')}...';
      });

      // FIX: Create proper Storage reference with correct path
      final String fileName = '${widget.userId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('verification_documents') // Main folder
          .child(widget.userId)            // User-specific subfolder
          .child(fileName);                // File name

      debugPrint('📤 Uploading to path: ${storageRef.fullPath}');

      // FIX: Upload with metadata for better file management
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': widget.userId,
          'documentType': documentType,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = storageRef.putFile(file, metadata);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
        debugPrint('Upload progress: ${(_uploadProgress * 100).toStringAsFixed(0)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // FIX: Verify upload was successful
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('✅ Upload successful: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('❌ Upload failed with state: ${snapshot.state}');
        throw Exception('Upload failed');
      }
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _uploadAllDocuments() async {
    // Validation
    if (_idCardFront == null && _idCardFrontUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please upload ID card front'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_idCardBack == null && _idCardBackUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please upload ID card back'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload ID Front (if new file selected)
      if (_idCardFront != null) {
        _idCardFrontUrl = await _uploadFile(_idCardFront!, 'id_front');
        if (_idCardFrontUrl == null) {
          throw Exception('Failed to upload ID front');
        }
      }

      // Upload ID Back (if new file selected)
      if (_idCardBack != null) {
        _idCardBackUrl = await _uploadFile(_idCardBack!, 'id_back');
        if (_idCardBackUrl == null) {
          throw Exception('Failed to upload ID back');
        }
      }

      // Upload Certificate (optional, if selected)
      if (_certificate != null) {
        _certificateUrl = await _uploadFile(_certificate!, 'certificate');
        // Certificate is optional, so we don't fail if it doesn't upload
      }

      // FIX: Save to Firestore with all URLs
      setState(() {
        _uploadStatus = 'Saving to database...';
      });

      await FirebaseFirestore.instance
          .collection('verificationDocuments')
          .doc(widget.userId)
          .set({
        'user_id': widget.userId,
        'id_card_front': _idCardFrontUrl,
        'id_card_back': _idCardBackUrl,
        'certificate': _certificateUrl,
        'status': 'pending',
        'uploaded_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // FIX: Use merge to update existing doc

      debugPrint('✅ Documents saved to Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documents uploaded successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        widget.onUploadComplete?.call();
      }
    } catch (e) {
      debugPrint('❌ Upload process failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your ID card and any professional certificates to verify your account',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 20),

        // ID Card Front
        _buildDocumentPicker(
          label: 'ID Card (Front) *',
          documentType: 'id_front',
          file: _idCardFront,
          existingUrl: _idCardFrontUrl,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),

        // ID Card Back
        _buildDocumentPicker(
          label: 'ID Card (Back) *',
          documentType: 'id_back',
          file: _idCardBack,
          existingUrl: _idCardBackUrl,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),

        // Certificate (Optional)
        _buildDocumentPicker(
          label: 'Professional Certificate (Optional)',
          documentType: 'certificate',
          file: _certificate,
          existingUrl: _certificateUrl,
          icon: Icons.workspace_premium,
        ),
        const SizedBox(height: 24),

        // Upload Progress
        if (_isUploading) ...[
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            _uploadStatus.isEmpty
                ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                : _uploadStatus,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Upload Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadAllDocuments,
            icon: _isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.cloud_upload),
            label: Text(_isUploading ? 'Uploading...' : 'Upload Documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Debug Info (remove in production)
        if (_idCardFrontUrl != null || _idCardBackUrl != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Documents Uploaded',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_idCardFrontUrl != null)
                  Text('✓ ID Front', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                if (_idCardBackUrl != null)
                  Text('✓ ID Back', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                if (_certificateUrl != null)
                  Text('✓ Certificate', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    required String documentType,
    required File? file,
    required String? existingUrl,
    required IconData icon,
  }) {
    final hasFile = file != null || existingUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : () => _pickImage(documentType),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: _isUploading ? Colors.grey.shade100 : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile ? AppColors.primary : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: hasFile
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (file != null)
                    Image.file(file, fit: BoxFit.cover)
                  else if (existingUrl != null)
                    Image.network(
                      existingUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) {
                        return const Center(
                          child: Icon(Icons.error, color: AppColors.error),
                        );
                      },
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: AppColors.success,
                      radius: 16,
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  if (!_isUploading)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Tap to change',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to upload',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'JPG, PNG (max 5MB)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}