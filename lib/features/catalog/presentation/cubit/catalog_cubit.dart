import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../application/use_cases/load_products.dart';
import '../../domain/entities/product.dart';

enum CatalogStatus { initial, loading, ready, loadingMore, failure }

final class CatalogState extends Equatable {
  const CatalogState({
    this.status = CatalogStatus.initial,
    this.products = const [],
    this.snapshotRevision = 0,
    this.afterId = '',
    this.hasMore = false,
    this.message,
  });

  final CatalogStatus status;
  final List<Product> products;
  final int snapshotRevision;
  final String afterId;
  final bool hasMore;
  final String? message;

  CatalogState copyWith({
    CatalogStatus? status,
    List<Product>? products,
    int? snapshotRevision,
    String? afterId,
    bool? hasMore,
    String? message,
  }) => CatalogState(
    status: status ?? this.status,
    products: products ?? this.products,
    snapshotRevision: snapshotRevision ?? this.snapshotRevision,
    afterId: afterId ?? this.afterId,
    hasMore: hasMore ?? this.hasMore,
    message: message,
  );

  @override
  List<Object?> get props => [
    status,
    products,
    snapshotRevision,
    afterId,
    hasMore,
    message,
  ];
}

final class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._load) : super(const CatalogState());
  final LoadProducts _load;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.status == CatalogStatus.loading) return;
    emit(state.copyWith(status: CatalogStatus.loading, message: null));
    try {
      final page = await _load();
      emit(
        CatalogState(
          status: CatalogStatus.ready,
          products: page.products,
          snapshotRevision: page.snapshotRevision,
          afterId: page.afterId,
          hasMore: page.hasMore,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(status: CatalogStatus.failure, message: failure.message),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == CatalogStatus.loadingMore) return;
    emit(state.copyWith(status: CatalogStatus.loadingMore));
    try {
      final page = await _load(
        afterId: state.afterId,
        snapshotRevision: state.snapshotRevision,
      );
      emit(
        state.copyWith(
          status: CatalogStatus.ready,
          products: [...state.products, ...page.products],
          afterId: page.afterId,
          hasMore: page.hasMore,
        ),
      );
    } on AppFailure catch (failure) {
      if (failure.code == FailureCode.snapshotExpired) {
        await load(refresh: true);
      } else {
        emit(
          state.copyWith(status: CatalogStatus.ready, message: failure.message),
        );
      }
    }
  }
}
