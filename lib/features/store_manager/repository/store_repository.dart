import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../../core/constants.dart';
import 'upload_service.dart';
import 'image_helper.dart';

class StoreRepository {
  final Dio _dio;
  final UploadService _uploader;
  final Box _box;

  StoreRepository._(this._dio, this._uploader, this._box);

  /// Test factory to create repository using a provided Dio and Hive box (for unit tests)
  static StoreRepository testCreate(Dio dio, Box box) {
    final uploader = UploadService(dio);
    return StoreRepository._(dio, uploader, box);
  }

  static Future<StoreRepository> create() async {
    final dio = Dio(BaseOptions(
        baseUrl: Constants.apiBaseUrl,
        connectTimeout: Duration(seconds: 7),
        receiveTimeout: Duration(seconds: 7)));
    final uploader = UploadService(dio);
    // Ensure box is open? It should be opened in bootstrap.
    final box = Hive.isBoxOpen('vendor_app_box')
        ? Hive.box('vendor_app_box')
        : await Hive.openBox('vendor_app_box');
    return StoreRepository._(dio, uploader, box);
  }

  // fetch items (try cache first)
  Future<List<Map<String, dynamic>>> fetchItems(
      {bool forceRemote = false}) async {
    final cache = _box.get('menu_cache');
    if (!forceRemote && cache != null) {
      try {
        final parsed = (cache as List)
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        // still attempt background refresh
        _refreshItemsInBackground();
        return parsed;
      } catch (_) {}
    }
    return _refreshItemsInBackground();
  }

  Future<List<Map<String, dynamic>>> _refreshItemsInBackground() async {
    try {
      final resp = await _dio.get('/vendors/me/items');
      final data = (resp.data as List)
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await _box.put('menu_cache', data);
      return data;
    } catch (e) {
      // fallback to cache if exists
      final cache = _box.get('menu_cache', defaultValue: []);
      return (cache as List)
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final resp = await _dio.get('/vendors/me/categories');
      final data = (resp.data as List)
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await _box.put('categories_cache', data);
      return data;
    } catch (e) {
      final cache = _box.get('categories_cache', defaultValue: []);
      return (cache as List)
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  Future<void> createCategory(String name) async {
    // API call to create category
    await _dio.post('/vendors/me/categories', data: {'name': name});
    await fetchCategories(); // refresh cache
  }

  Future<Map<String, dynamic>> createItem({
    required String name,
    required double price,
    required bool veg,
    required int stock,
    required String category,
    File? imageFile,
    Function(int, int)? onUploadProgress,
  }) async {
    File? fileToUpload = imageFile;
    String? cancelId;
    if (imageFile != null) {
      final res =
          await ImageHelper.compressFileCancelable(imageFile, quality: 75);
      fileToUpload = res['file'] as File;
      cancelId = res['cancelId'] as String?;
    }
    try {
      if (fileToUpload != null) {
        // use multipart
        final item = await _uploader.uploadItemWithImage(
          name: name,
          price: price,
          veg: veg,
          stock: stock,
          category: category,
          image: fileToUpload,
          onProgress: onUploadProgress,
        );
        // cleanup compressed file if it is a temp created by us and different from original
        if (fileToUpload.path != imageFile?.path) {
          try {
            fileToUpload.deleteSync();
          } catch (_) {}
        }
        await invalidateCache();
        return item;
      } else {
        final resp = await _dio.post('/vendors/me/items', data: {
          'name': name,
          'price': price,
          'veg': veg,
          'stock': stock,
          'category': category,
        });
        await invalidateCache();
        return Map<String, dynamic>.from(resp.data);
      }
    } catch (e) {
      // if compressed tmp exists, keep it for retry; or delete if cancelled
      if (cancelId != null) {
        ImageHelper.cancelCompression(cancelId);
      }
      // offline -> put into pending_item_actions queue in Hive
      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      final pending =
          _box.get('pending_item_actions', defaultValue: []) as List;
      pending.add({
        'uuid': uuid,
        'type': 'create',
        'payload': {
          'name': name,
          'price': price,
          'veg': veg,
          'stock': stock,
          'category': category
        },
        'imagePath': imageFile?.path,
        'attempts': 0,
        'createdAt': DateTime.now().toIso8601String()
      });
      await _box.put('pending_item_actions', pending);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateItem({
    required String id,
    required String name,
    required double price,
    required bool veg,
    required int stock,
    required String category,
    File? imageFile,
    Function(int, int)? onUploadProgress,
  }) async {
    try {
      if (imageFile != null) {
        final item = await _uploader.uploadItemWithImage(
            id: id,
            name: name,
            price: price,
            veg: veg,
            stock: stock,
            category: category,
            image: imageFile,
            onProgress: onUploadProgress);
        await invalidateCache();
        return item;
      } else {
        final resp = await _dio.put('/vendors/me/items/$id', data: {
          'name': name,
          'price': price,
          'veg': veg,
          'stock': stock,
          'category': category,
        });
        await invalidateCache();
        return Map<String, dynamic>.from(resp.data);
      }
    } catch (e) {
      // enqueue pending update
      final pending =
          _box.get('pending_item_actions', defaultValue: []) as List;
      pending.add({
        'uuid': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'update',
        'itemId': id,
        'payload': {
          'name': name,
          'price': price,
          'veg': veg,
          'stock': stock,
          'category': category
        },
        'imagePath': imageFile?.path,
        'attempts': 0,
        'createdAt': DateTime.now().toIso8601String()
      });
      await _box.put('pending_item_actions', pending);
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _dio.delete('/vendors/me/items/$id');
      await invalidateCache();
    } catch (e) {
      final pending =
          _box.get('pending_item_actions', defaultValue: []) as List;
      pending.add({
        'uuid': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'delete',
        'itemId': id,
        'attempts': 0,
        'createdAt': DateTime.now().toIso8601String()
      });
      await _box.put('pending_item_actions', pending);
      rethrow;
    }
  }

  Future<void> invalidateCache() async {
    await _box.delete('menu_cache');
    // optionally trigger refresh
    await _refreshItemsInBackground();
  }

  // Sync pending item actions - called on app resume or periodic
  Future<void> syncPendingItemActions() async {
    final pending = _box.get('pending_item_actions', defaultValue: []) as List;
    if (pending.isEmpty) return;
    final List remaining = [];
    for (var p in pending) {
      try {
        final type = p['type'];
        final payload = Map<String, dynamic>.from(p['payload'] ?? {});
        final imagePath = p['imagePath'] as String?;
        if (type == 'create') {
          await createItem(
            name: payload['name'],
            price: (payload['price'] as num).toDouble(),
            veg: payload['veg'] as bool,
            stock: payload['stock'] as int,
            category: payload['category'] ?? 'General',
            imageFile: imagePath != null ? File(imagePath) : null,
          );
        } else if (type == 'update') {
          await updateItem(
            id: p['itemId'],
            name: payload['name'],
            price: (payload['price'] as num).toDouble(),
            veg: payload['veg'] as bool,
            stock: payload['stock'] as int,
            category: payload['category'] ?? 'General',
            imageFile: imagePath != null ? File(imagePath) : null,
          );
        } else if (type == 'delete') {
          await deleteItem(p['itemId']);
        }
      } catch (e) {
        // keep item in queue, increment attempts
        p['attempts'] = (p['attempts'] ?? 0) + 1;
        // keep in remaining
        remaining.add(p);
      }
    }
    await _box.put('pending_item_actions', remaining);
  }
}
