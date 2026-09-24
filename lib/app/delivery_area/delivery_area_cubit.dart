import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/secure_key_value_store.dart';

const defaultDeliveryArea = 'Bria Homes';

final class DeliveryAreaState {
  const DeliveryAreaState({
    this.area = defaultDeliveryArea,
    this.loading = false,
  });

  final String area;
  final bool loading;
}

/// Keeps a customer's preferred address on this device, separate per account.
final class DeliveryAreaCubit extends Cubit<DeliveryAreaState> {
  DeliveryAreaCubit(this._store) : super(const DeliveryAreaState());

  final SecureKeyValueStore _store;
  String? _userId;
  int _revision = 0;

  Future<void> loadFor(String userId) async {
    if (_userId == userId) return;
    _userId = userId;
    final revision = ++_revision;
    emit(const DeliveryAreaState(loading: true));
    try {
      final saved = await _store.read(_key(userId));
      if (_revision != revision || isClosed) return;
      emit(DeliveryAreaState(area: _valid(saved) ?? defaultDeliveryArea));
    } catch (_) {
      if (_revision != revision || isClosed) return;
      emit(const DeliveryAreaState());
    }
  }

  Future<bool> save(String value) async {
    final userId = _userId;
    final area = _valid(value);
    if (userId == null || area == null || state.loading) return false;
    final revision = ++_revision;
    try {
      await _store.write(_key(userId), area);
      if (_revision != revision || isClosed) return false;
      emit(DeliveryAreaState(area: area));
      return true;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    _userId = null;
    ++_revision;
    emit(const DeliveryAreaState());
  }

  static String _key(String userId) => 'customer_delivery_area:$userId';

  static String? _valid(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty || trimmed.length > 500
        ? null
        : trimmed;
  }
}
