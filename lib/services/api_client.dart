import 'package:dio/dio.dart';

class ApiClient {
  // ApiClient._(); // Removed as it doesn't init _dio
  static late final ApiClient instance;
  final Dio _dio;

  static void init({required String baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: 7),
        receiveTimeout: Duration(seconds: 7),
      ),
    );
    // Add interceptors for auth header & retry if needed
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // TODO: attach JWT from secure storage if present
          return handler.next(options);
        },
        onError: (e, handler) {
          return handler.next(e);
        },
      ),
    );
    instance = ApiClient._create(dio);
  }

  ApiClient._create(this._dio);

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);
  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}
