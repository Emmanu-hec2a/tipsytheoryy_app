import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (_image == null) return;
    setState(() => _isUploading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // We reuse updateProfile to upload the "Midnight Mirror" selfie
      // In a real scenario, this might hit a specific verification endpoint
      final success = await userProvider.updateProfile(
        imagePath: _image!.path,
        data: {'is_age_verified': true},
      );

      if (success && mounted) {
        widget.onVerified();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
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
            const Icon(Icons.verified_user_rounded, color: AppTheme.accentColor, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Midnight Mirror',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Quick check to continue! Please take a clear selfie to confirm your identity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _image != null ? AppTheme.accentColor : (isDark ? Colors.white10 : Colors.grey.shade300),
                    width: 4,
                  ),
                ),
                child: _image != null
                    ? ClipOval(child: Image.file(_image!, fit: BoxFit.cover))
                    : Icon(Icons.camera_alt_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey),
              ),
            ),
            const Spacer(),
            const Text(
              'Secure & private. Used only for age confirmation.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_image == null || _isUploading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'VERIFY NOW',
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
