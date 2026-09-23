import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/use_cases/update_cart.dart';
import '../../domain/entities/cart.dart';

final class CartState extends Equatable {
  const CartState({this.lines = const [], this.unavailableIds = const {}});
  final List<CartLine> lines;
  final Set<String> unavailableIds;
  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);
  int get totalCentavos =>
      lines.fold(0, (total, line) => total + line.lineTotalCentavos);

  @override
  List<Object?> get props => [lines, unavailableIds];
}

final class CartCubit extends Cubit<CartState> {
  CartCubit(this._cart) : super(CartState(lines: _cart.read()));
  final UpdateCart _cart;

  void add(CartProduct product) {
    final lines = [...state.lines];
    final index = lines.indexWhere((line) => line.product.id == product.id);
    if (index < 0) {
      lines.add(CartLine(product: product, quantity: 1));
    } else if (lines[index].quantity < 100) {
      lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
    }
    _emit(lines, unavailable: {...state.unavailableIds}..remove(product.id));
  }

  void decrement(String productId) {
    final lines = [...state.lines];
    final index = lines.indexWhere((line) => line.product.id == productId);
    if (index < 0) return;
    if (lines[index].quantity == 1) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(quantity: lines[index].quantity - 1);
    }
    _emit(lines);
  }

  void remove(String productId) =>
      _emit(state.lines.where((line) => line.product.id != productId).toList());

  void markUnavailable(Iterable<String> productIds) {
    emit(CartState(lines: state.lines, unavailableIds: productIds.toSet()));
  }

  void clear() {
    _cart.clear();
    emit(const CartState());
  }

  void _emit(List<CartLine> lines, {Set<String>? unavailable}) {
    _cart.replace(lines);
    emit(
      CartState(
        lines: lines,
        unavailableIds: unavailable ?? state.unavailableIds,
      ),
    );
  }
}
