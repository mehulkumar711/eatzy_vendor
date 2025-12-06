import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:hive/hive.dart';
import 'package:eatzy_vendor/features/store_manager/repository/store_repository.dart';
import '../helpers/hive_test_helper.dart';

void main() {
  test('fetchItems uses API and caches result', () async {
    // start Hive in-memory
    final cleanup = await HiveTestHelper.initHiveForTest();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = DioAdapter(dio: dio);

    adapter.onGet(
        '/vendors/me/items',
        (server) => server.reply(200, [
              {
                'id': 'i1',
                'name': 'Dabeli',
                'price': 40,
                'veg': true,
                'stock': 10,
                'category': 'Snacks'
              }
            ]));

    final box = Hive.box('vendor_app_box');
    final repo = StoreRepository.testCreate(dio, box);

    final items = await repo.fetchItems(forceRemote: true);
    expect(items.length, 1);
    expect(items[0]['name'], 'Dabeli');

    // cached
    final cached = await repo.fetchItems(forceRemote: false);
    expect(cached.length, 1);

    cleanup();
  });
}
