import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';

final class UpdateCart {
  const UpdateCart(this._repository);
  final CartRepository _repository;

  List<CartLine> read() => _repository.lines;
  void replace(List<CartLine> lines) => _repository.replace(lines);
  void clear() => _repository.clear();
}
