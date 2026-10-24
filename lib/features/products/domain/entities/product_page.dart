import 'package:pooja_pasal/features/products/domain/entities/product.dart';

/// One page of a paginated product query. [cursor] is an opaque pagination
/// token — only `ProductRemoteDataSource` knows its concrete type (the
/// next page number); nothing above the data source layer should inspect
/// it, just pass it back into the next fetch.
class ProductPage {
  final List<Product> items;
  final Object? cursor;
  final bool hasMore;

  const ProductPage({required this.items, required this.cursor, required this.hasMore});
}
