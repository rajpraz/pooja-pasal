import 'package:pooja_pasal/features/wishlist/data/datasources/wishlist_remote_data_source.dart';
import 'package:pooja_pasal/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:pooja_pasal/features/wishlist/domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource _dataSource;

  WishlistRepositoryImpl(this._dataSource);

  @override
  Stream<List<WishlistItem>> streamWishlist(String uid) =>
      _dataSource.streamWishlist(uid);

  @override
  Future<bool> toggle(String uid, String productId) =>
      _dataSource.toggle(uid, productId);

  @override
  Future<void> remove(String uid, String productId) =>
      _dataSource.remove(uid, productId);
}
