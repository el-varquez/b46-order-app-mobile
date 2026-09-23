import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';

final class MemoryCartRepository implements CartRepository {
  List<CartLine> _lines = const [];

  @override
  List<CartLine> get lines => List.unmodifiable(_lines);

  @override
  void replace(List<CartLine> lines) => _lines = List.unmodifiable(lines);

  @override
  void clear() => _lines = const [];
}
