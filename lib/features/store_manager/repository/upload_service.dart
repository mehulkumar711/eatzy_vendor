import 'dart:io';
import 'package:dio/dio.dart';

class UploadService {
  final Dio _dio;
  UploadService(this._dio);

  // create or update item with image
  Future<Map<String, dynamic>> uploadItemWithImage({
    String? id,
    required String name,
    required double price,
    required bool veg,
    required int stock,
    required String category,
    required File image,
    Function(int, int)? onProgress,
  }) async {
    final fileName = image.path.split('/').last;
    final form = FormData.fromMap({
      if (id != null) '_id': id,
      'name': name,
      'price': price,
      'veg': veg,
      'stock': stock,
      'category': category,
      'image': await MultipartFile.fromFile(image.path, filename: fileName),
    });

    // If ID is provided, we usually PUT/PATCH, but the user spec says POST /vendors/me/items for create
    // and PUT /vendors/me/items/{id} for update.
    // However, the snippet provided used:
    // final path = id == null ? '/vendors/me/items' : '/vendors/me/items/$id';
    // final resp = await _dio.post(path, ...); <-- It used POST for both in the snippet provided?
    // Let's re-read the snippet carefully.

    // Snippet:
    // final path = id == null ? '/vendors/me/items' : '/vendors/me/items/$id';
    // final resp = await _dio.post(path, ...);

    // BUT the API Contract in the prompt says:
    // PUT /vendors/me/items/{id} → multipart/form-data (same fields) or JSON when no image

    // I will use PUT if id is present.
    final path = id == null ? '/vendors/me/items' : '/vendors/me/items/$id';

    Response resp;
    if (id == null) {
      resp = await _dio.post(path, data: form, onSendProgress: onProgress);
    } else {
      resp = await _dio.put(path, data: form, onSendProgress: onProgress);
    }

    return Map<String, dynamic>.from(resp.data);
  }
}
