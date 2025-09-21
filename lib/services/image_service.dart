// lib/services/image_service.dart
import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<String?> pickAndCompressImage() async {
    try {
      // Pick image from gallery or camera
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,  // Low resolution as requested
        maxHeight: 400,
        imageQuality: 70,  // Compress to 70% quality
      );
      
      if (pickedFile == null) return null;
      
      // Read file bytes
      final bytes = await pickedFile.readAsBytes();
      
      // Further compress using image package
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      
      // Resize to maximum 200x200 for low resolution
      image = img.copyResize(image, width: 200, height: 200);
      
      // Convert to JPEG with compression
      final compressedBytes = img.encodeJpg(image, quality: 60);
      
      // Convert to base64
      final base64String = base64Encode(compressedBytes);
      
      // Return data URL format
      return 'data:image/jpeg;base64,$base64String';
      
    } catch (e) {
      print('Image compression error: $e');
      return null;
    }
  }
  
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      
      if (pickedFile == null) return null;
      
      final bytes = await pickedFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      
      image = img.copyResize(image, width: 200, height: 200);
      final compressedBytes = img.encodeJpg(image, quality: 60);
      final base64String = base64Encode(compressedBytes);
      
      return 'data:image/jpeg;base64,$base64String';
      
    } catch (e) {
      print('Camera image error: $e');
      return null;
    }
  }
}
