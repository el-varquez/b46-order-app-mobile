import 'package:b46_order_app_mobile/app/theme/app_theme.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/application/use_cases/update_cart.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/data/repositories/memory_cart_repository.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/domain/entities/cart.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/presentation/cubit/cart_cubit.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/presentation/screens/checkout_screen.dart';
import 'package:b46_order_app_mobile/features/catalog/application/use_cases/load_products.dart';
import 'package:b46_order_app_mobile/features/catalog/domain/entities/product.dart';
import 'package:b46_order_app_mobile/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:b46_order_app_mobile/features/catalog/presentation/cubit/catalog_cubit.dart';
import 'package:b46_order_app_mobile/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('catalog grid and checkout fit a 320px phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final catalog = CatalogCubit(LoadProducts(_CatalogRepository()));
    final cart = CartCubit(UpdateCart(MemoryCartRepository()));
    await catalog.load();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: catalog),
          BlocProvider.value(value: cart),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: CatalogScreen(
            cartCount: 0,
            onAdd: (_) {},
            onCart: () {},
            onOrders: () {},
            onSignOut: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Coke 1.5L'), findsOneWidget);
    expect(tester.takeException(), isNull);

    cart.add(
      const CartProduct(id: 'coke', name: 'Coke 1.5L', unitPriceCentavos: 8200),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cart,
        child: MaterialApp(
          theme: AppTheme.light,
          home: CheckoutScreen(
            placing: false,
            message: null,
            onPlace: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Place order'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await catalog.close();
    await cart.close();
  });
}

final class _CatalogRepository implements CatalogRepository {
  @override
  Future<ProductPage> products({
    int limit = 20,
    String afterId = '',
    int snapshotRevision = 0,
  }) async => const ProductPage(
    products: [
      Product(
        id: 'coke',
        name: 'Coke 1.5L',
        description: 'Chilled bottle',
        priceCentavos: 8200,
        categoryId: 'drinks',
        categoryName: 'Drinks',
        available: true,
      ),
    ],
    snapshotRevision: 1,
    afterId: '',
    hasMore: false,
  );
}
