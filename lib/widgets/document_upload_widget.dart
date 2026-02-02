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

  String? _idCardFrontUrl;
  String? _idCardBackUrl;
  String? _certificateUrl;

  Future<void> _pickImage(String documentType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          switch (documentType) {
            case 'id_front':
              _idCardFront = File(pickedFile.path);
              break;
            case 'id_back':
              _idCardBack = File(pickedFile.path);
              break;
            case 'certificate':
              _certificate = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadFile(File file, String documentType) async {
    try {
      final String fileName = '${widget.userId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('verification_documents')
          .child(widget.userId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _uploadAllDocuments() async {
    // Validation
    if (_idCardFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please upload ID card front')),
      );
      return;
    }

    if (_idCardBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please upload ID card back')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload ID Front
      _idCardFrontUrl = await _uploadFile(_idCardFront!, 'id_front');

      // Upload ID Back
      _idCardBackUrl = await _uploadFile(_idCardBack!, 'id_back');

      // Upload Certificate (optional)
      if (_certificate != null) {
        _certificateUrl = await _uploadFile(_certificate!, 'certificate');
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('verificationDocuments')
          .doc(widget.userId)
          .set({
        'user_id': widget.userId,
        'id_card_front': _idCardFrontUrl,
        'id_card_back': _idCardBackUrl,
        'certificate': _certificateUrl,
        'status': 'pending', // pending, approved, rejected
        'uploaded_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documents uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        widget.onUploadComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
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
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),

        // ID Card Back
        _buildDocumentPicker(
          label: 'ID Card (Back) *',
          documentType: 'id_back',
          file: _idCardBack,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),

        // Certificate (Optional)
        _buildDocumentPicker(
          label: 'Professional Certificate (Optional)',
          documentType: 'certificate',
          file: _certificate,
          icon: Icons.workspace_premium,
        ),
        const SizedBox(height: 24),

        // Upload Progress
        if (_isUploading) ...[
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
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
      ],
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    required String documentType,
    required File? file,
    required IconData icon,
  }) {
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
          onTap: () => _pickImage(documentType),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file != null ? AppColors.primary : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: file != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    file,
                    fit: BoxFit.cover,
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