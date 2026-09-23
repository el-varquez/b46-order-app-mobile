import '../entities/cart.dart';

abstract interface class CartRepository {
  List<CartLine> get lines;
  void replace(List<CartLine> lines);
  void clear();
}
