import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim() ?? '';
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim() ?? '';
  String get _folder => dotenv.env['CLOUDINARY_FOLDER']?.trim() ?? '';

  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  Future<String> uploadImage(XFile file) async {
    if (!isConfigured) {
      throw Exception('Cloudinary is not configured. Please update your .env file.');
    }

    try {
      final bytes = await file.readAsBytes();
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: FormData.fromMap({
          'upload_preset': _uploadPreset,
          if (_folder.isNotEmpty) 'folder': _folder,
          'file': MultipartFile.fromBytes(
            bytes,
            filename: file.name.isEmpty ? 'upload.jpg' : file.name,
          ),
        }),
      );

      final secureUrl = response.data?['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary did not return a secure_url.');
      }

      return secureUrl;
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['error']?['message'] as String?)
          : null;
      throw Exception(message ?? 'Failed to upload image to Cloudinary.');
    }
  }
}
