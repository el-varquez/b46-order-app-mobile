import 'package:b46_order_app_mobile/app/delivery_area/delivery_area_cubit.dart';
import 'package:b46_order_app_mobile/core/storage/secure_key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delivery area persists per customer and resets on sign-out', () async {
    final store = _MemoryStore();
    final area = DeliveryAreaCubit(store);

    await area.loadFor('customer-a');
    expect(area.state.area, defaultDeliveryArea);
    expect(await area.save('  Block 8, Lot 2, Bria Homes  '), isTrue);
    expect(area.state.area, 'Block 8, Lot 2, Bria Homes');
    expect(await area.save('   '), isFalse);

    area.clear();
    expect(area.state.area, defaultDeliveryArea);
    await area.loadFor('customer-b');
    expect(area.state.area, defaultDeliveryArea);

    area.clear();
    await area.loadFor('customer-a');
    expect(area.state.area, 'Block 8, Lot 2, Bria Homes');
    await area.close();
  });
}

final class _MemoryStore implements SecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
