import 'package:b46_order_app_mobile/features/cart_checkout/application/use_cases/update_cart.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/data/repositories/memory_cart_repository.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/domain/entities/cart.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/presentation/cubit/cart_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cart updates quantity and integer-centavo total', () {
    final cubit = CartCubit(UpdateCart(MemoryCartRepository()));
    const product = CartProduct(
      id: 'coke',
      name: 'Coke',
      unitPriceCentavos: 8250,
    );
    cubit.add(product);
    cubit.add(product);
    expect(cubit.state.itemCount, 2);
    expect(cubit.state.totalCentavos, 16500);
    cubit.decrement(product.id);
    expect(cubit.state.itemCount, 1);
  });

  test('unavailable lines remain in cart and are marked', () {
    final cubit = CartCubit(UpdateCart(MemoryCartRepository()));
    const product = CartProduct(
      id: 'milk',
      name: 'Milk',
      unitPriceCentavos: 9500,
    );
    cubit.add(product);
    cubit.markUnavailable([product.id]);
    expect(cubit.state.lines, hasLength(1));
    expect(cubit.state.unavailableIds, contains(product.id));
  });
}
