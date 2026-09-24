import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/customer_shell.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../domain/entities/product.dart';
import '../components/add_to_basket_flight.dart';
import '../cubit/catalog_cubit.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    required this.cartCount,
    required this.onAdd,
    required this.onCart,
    required this.onOrders,
    required this.onSignOut,
    this.deliveryArea = 'Bria Homes',
    this.onProfile,
    super.key,
  });

  final int cartCount;
  final ValueChanged<Product> onAdd;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final VoidCallback onSignOut;
  final String deliveryArea;
  final VoidCallback? onProfile;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final search = TextEditingController();
  final basketButtonKey = GlobalKey();
  final flights = <OverlayEntry>{};
  String category = 'All';

  @override
  void initState() {
    super.initState();
    search.addListener(_refreshSearch);
  }

  void _refreshSearch() => setState(() {});

  void _animateAdd(Product product, BuildContext cardContext) {
    if (MediaQuery.of(context).disableAnimations) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject();
    final cardBox = cardContext.findRenderObject();
    final basketBox = basketButtonKey.currentContext?.findRenderObject();
    if (overlayBox is! RenderBox ||
        cardBox is! RenderBox ||
        basketBox is! RenderBox) {
      return;
    }
    final start = cardBox.localToGlobal(
      Offset(cardBox.size.width / 2, cardBox.size.height * 0.35),
      ancestor: overlayBox,
    );
    final end = basketBox.localToGlobal(
      basketBox.size.center(Offset.zero),
      ancestor: overlayBox,
    );
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: AddToBasketFlight(
          key: const Key('add-to-basket-flight'),
          start: start,
          end: end,
          itemIcon: _categoryIcon(product.categoryName),
          imageUrl: product.imageUrl,
          onFinished: () {
            if (!flights.remove(entry)) return;
            entry.remove();
            entry.dispose();
          },
        ),
      ),
    );
    flights.add(entry);
    overlay.insert(entry);
  }

  @override
  void dispose() {
    for (final entry in flights) {
      entry.remove();
      entry.dispose();
    }
    flights.clear();
    search.removeListener(_refreshSearch);
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomerTheme(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: CustomerHeader(
          title: widget.deliveryArea,
          subtitle: 'Delivering to',
          action: IconButton(
            key: basketButtonKey,
            tooltip: 'Your basket',
            onPressed: widget.onCart,
            icon: const Icon(PopIcons.basket),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.cartCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: FilledButton(
                  key: const Key('view-cart'),
                  onPressed: widget.onCart,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your basket',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.cartCount} item${widget.cartCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'View cart  →',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            CustomerBottomNav(
              selected: 'Shop',
              onShop: () {},
              onOrders: widget.onOrders,
              onProfile: widget.onProfile ?? () {},
            ),
          ],
        ),
        body: BlocBuilder<CatalogCubit, CatalogState>(
          builder: (context, state) {
            if (state.status == CatalogStatus.loading &&
                state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == CatalogStatus.failure &&
                state.products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message ?? 'Could not load products.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            context.read<CatalogCubit>().load(refresh: true),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final query = search.text.trim().toLowerCase();
            final categories = <String>[
              'All',
              ...{for (final product in state.products) product.categoryName},
            ];
            final visible = state.products
                .where(
                  (product) =>
                      (category == 'All' || product.categoryName == category) &&
                      (query.isEmpty ||
                          '${product.name} ${product.description}'
                              .toLowerCase()
                              .contains(query)),
                )
                .toList(growable: false);
            return RefreshIndicator(
              onRefresh: () => context.read<CatalogCubit>().load(refresh: true),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    sliver: SliverList.list(
                      children: [
                        const _ShopHero(),
                        const SizedBox(height: 15),
                        TextField(
                          key: const Key('product-search'),
                          controller: search,
                          decoration: const InputDecoration(
                            hintText: 'Search snacks, drinks, essentials',
                            prefixIcon: Icon(PopIcons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories
                                .map(
                                  (value) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(value),
                                      selected: category == value,
                                      onSelected: (_) =>
                                          setState(() => category = value),
                                      showCheckmark: false,
                                      backgroundColor: CustomerPalette.soft(
                                        context,
                                      ),
                                      selectedColor: CustomerPalette.ink(
                                        context,
                                      ),
                                      labelStyle: TextStyle(
                                        color: category == value
                                            ? CustomerPalette.paper(context)
                                            : CustomerPalette.ink(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      side: BorderSide.none,
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Trending at B46',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'Available now',
                              style: TextStyle(
                                color: CustomerPalette.muted(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  if (visible.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No products match your search.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.63,
                              crossAxisSpacing: 11,
                              mainAxisSpacing: 11,
                            ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) => ProductCard(
                          product: visible[index],
                          onAdd: widget.onAdd,
                          onAnimateAdd: _animateAdd,
                        ),
                      ),
                    ),
                  if (state.hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: OutlinedButton(
                          onPressed: state.status == CatalogStatus.loadingMore
                              ? null
                              : context.read<CatalogCubit>().loadMore,
                          child: Text(
                            state.status == CatalogStatus.loadingMore
                                ? 'Loading…'
                                : 'Load more products',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _ShopHero extends StatelessWidget {
  const _ShopHero();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
    decoration: const BoxDecoration(
      color: PopColors.launchRed,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(48),
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      boxShadow: [
        BoxShadow(color: PopColors.launchShadow, offset: Offset(8, 8)),
      ],
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'B46 snack drop',
          style: TextStyle(color: PopColors.white, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 7),
        Text(
          'BIG CRAVINGS.\nSMALL TRIP.',
          style: TextStyle(
            color: PopColors.white,
            fontSize: 38,
            height: 0.94,
            letterSpacing: -1.9,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Fresh picks delivered around Bria',
          style: TextStyle(
            color: PopColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onAdd,
    this.onAnimateAdd,
    super.key,
  });
  final Product product;
  final ValueChanged<Product> onAdd;
  final void Function(Product, BuildContext)? onAnimateAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: CustomerPalette.surface(context),
      borderRadius: BorderRadius.circular(9),
      boxShadow: [
        BoxShadow(
          color: PopColors.launchShadow.withValues(alpha: 0.12),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: ColoredBox(
              color: CustomerPalette.soft(context),
              child: SizedBox.expand(
                child: product.imageUrl == null
                    ? Icon(_categoryIcon(product.categoryName), size: 52)
                    : Image.network(
                        product.imageUrl.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(_categoryIcon(product.categoryName), size: 52),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: CustomerPalette.muted(context), fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _money(product.priceCentavos),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: product.available ? 60 : 68,
              height: 42,
              child: FilledButton(
                onPressed: product.available
                    ? () {
                        onAdd(product);
                        onAnimateAdd?.call(product, context);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  product.available ? '+ Add' : 'Sold out',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('drink')) return PopIcons.drink;
  if (value.contains('pantry')) return PopIcons.pantry;
  return PopIcons.groceries;
}

String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
