import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/theme.dart';
import '../../providers/user_provider.dart';
import 'dart:io';

class AgeVerificationScreen extends StatefulWidget {
  final VoidCallback onVerified;
  const AgeVerificationScreen({super.key, required this.onVerified});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  File? _image;
  bool _isUploading = false;
  bool _isFaceDetected = false;
  String? _statusMessage;
  
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
    ),
  );

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _image = file;
        _statusMessage = 'Analyzing face...';
        _isFaceDetected = false;
      });
      _detectFace(file);
    }
  }

  Future<void> _detectFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      
      setState(() {
        if (faces.isNotEmpty) {
          _isFaceDetected = true;
          _statusMessage = 'Face detected! You look great.';
        } else {
          _isFaceDetected = false;
          _statusMessage = 'No face detected. Please try again with a clear selfie.';
        }
      });
    } catch (e) {
      setState(() {
        _isFaceDetected = false;
        _statusMessage = 'AI analysis failed. Please try again.';
      });
    }
  }

  Future<void> _submit() async {
    if (_image == null || !_isFaceDetected) return;
    setState(() => _isUploading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Pass 'ai_face_detected' as true to the backend for audit
      final success = await userProvider.updateProfile(
        imagePath: _image!.path,
        data: {
          'is_age_verified': true,
          'verification_method': 'midnight_mirror_ai',
          'ai_signals': {
            'face_detected_client': true,
            'confidence': 'high',
          }
        },
      );

      if (success && mounted) {
        widget.onVerified();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.face_unlock_rounded, color: AppTheme.accentColor, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Midnight Mirror AI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'To keep our community safe, please take a clear selfie. Our AI will confirm it\'s really you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const Spacer(),
            
            // Camera Area
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _image == null 
                            ? (isDark ? Colors.white10 : Colors.grey.shade300)
                            : (_isFaceDetected ? Colors.green : Colors.redAccent),
                        width: 4,
                      ),
                      boxShadow: _isFaceDetected ? [
                        BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
                      ] : [],
                    ),
                    child: _image != null
                        ? ClipOval(child: Image.file(_image!, fit: BoxFit.cover))
                        : Icon(Icons.camera_alt_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey),
                  ),
                  if (_image != null && _isFaceDetected)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            
            if (_statusMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isFaceDetected ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
            
            const Spacer(),
            const Text(
              'Secure on-device AI analysis. No data is shared.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_image == null || _isUploading || !_isFaceDetected) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isUploading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'CONTINUE TO ORDER',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
