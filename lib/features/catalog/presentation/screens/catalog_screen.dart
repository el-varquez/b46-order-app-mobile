import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../../domain/entities/product.dart';
import '../cubit/catalog_cubit.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({
    required this.cartCount,
    required this.onAdd,
    required this.onCart,
    required this.onOrders,
    required this.onSignOut,
    super.key,
  });

  final int cartCount;
  final ValueChanged<Product> onAdd;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      title: const B46Mark(),
      actions: [
        IconButton(
          onPressed: onOrders,
          tooltip: 'My orders',
          icon: const Icon(PopIcons.orders),
        ),
        IconButton(
          onPressed: onSignOut,
          tooltip: 'Sign out',
          icon: const Icon(PopIcons.signOut),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(PopSpace.md),
        child: FilledButton.icon(
          key: const Key('view-cart'),
          onPressed: onCart,
          icon: const Icon(PopIcons.basket),
          label: Text(
            cartCount == 0
                ? 'Your basket'
                : 'View basket · $cartCount item${cartCount == 1 ? '' : 's'}',
          ),
        ),
      ),
    ),
    child: BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        if (state.status == CatalogStatus.loading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == CatalogStatus.failure && state.products.isEmpty) {
          return EmptyState(
            title: 'Couldn’t load the shelf',
            message: state.message ?? 'Try again in a moment.',
          );
        }
        if (state.products.isEmpty) {
          return const EmptyState(
            title: 'The shelf is empty',
            message: 'Please check again soon.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<CatalogCubit>().load(refresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(PopSpace.md),
                  padding: const EdgeInsets.all(PopSpace.lg),
                  decoration: BoxDecoration(
                    color: PopColors.brandRed,
                    borderRadius: BorderRadius.circular(PopRadius.lg),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'B46 snack drop',
                        style: TextStyle(
                          color: PopColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: PopSpace.sm),
                      Text(
                        'BIG CRAVINGS.\nSMALL TRIP.',
                        style: TextStyle(
                          color: PopColors.white,
                          fontSize: 30,
                          height: 0.96,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: PopSpace.sm),
                      Text(
                        'Fresh picks delivered around Bria',
                        style: TextStyle(color: PopColors.white),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: PopSpace.md),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: PopSpace.sm,
                    mainAxisSpacing: PopSpace.sm,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) =>
                      ProductCard(product: state.products[index], onAdd: onAdd),
                ),
              ),
              if (state.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(PopSpace.md),
                    child: OutlinedButton(
                      onPressed: state.status == CatalogStatus.loadingMore
                          ? null
                          : context.read<CatalogCubit>().loadMore,
                      child: Text(
                        state.status == CatalogStatus.loadingMore
                            ? 'Loading…'
                            : 'Load more',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onAdd, super.key});
  final Product product;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(PopSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(PopRadius.sm),
              ),
              child: Center(
                child: Icon(_categoryIcon(product.categoryName), size: 52),
              ),
            ),
          ),
          const SizedBox(height: PopSpace.sm),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: PopSpace.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  _money(product.priceCentavos),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 68),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: product.available ? () => onAdd(product) : null,
                  child: Text(product.available ? '+ Add' : 'Sold out'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('drink')) return PopIcons.drink;
    if (value.contains('pantry')) return PopIcons.pantry;
    return PopIcons.groceries;
  }
}

String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
