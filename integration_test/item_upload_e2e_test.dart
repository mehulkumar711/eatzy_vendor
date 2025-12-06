import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:eatzy_vendor/features/store_manager/repository/store_repository.dart';
import 'package:hive/hive.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('e2e create item with image', (WidgetTester tester) async {
    // initialize hive
    final tmp = await getTemporaryDirectory();
    Hive.init(tmp.path);
    if (!Hive.isBoxOpen('vendor_app_box')) {
      await Hive.openBox('vendor_app_box');
    }

    // prepare a small sample file (write a tiny jpg or text pretending image)
    final tmpFile = File('${tmp.path}/test_image.jpg');
    await tmpFile.writeAsBytes(List.generate(5000, (i) => i % 256));

    // create Dio pointing to mock server running locally
    // Use 10.0.2.2 for Android emulator to access host localhost
    // Use Dart Define if available, else localhost fallback
    const apiUrl = String.fromEnvironment('EATZY_API_BASE_URL',
        defaultValue: 'http://10.0.2.2:3000');
    final dio = Dio(BaseOptions(baseUrl: apiUrl));
    final repo = StoreRepository.testCreate(dio, Hive.box('vendor_app_box'));

    // call createItem with image
    bool progressCalled = false;
    final item = await repo.createItem(
        name: 'E2E Test Item',
        price: 99.0,
        veg: true,
        stock: 5,
        category: 'Test',
        imageFile: tmpFile,
        onUploadProgress: (sent, total) {
          // print('upload progress $sent/$total');
          progressCalled = true;
        });

    expect(item['name'], 'E2E Test Item');
    expect(progressCalled, true);

    // cleanup
    try {
      tmpFile.deleteSync();
    } catch (_) {}
  });
}
