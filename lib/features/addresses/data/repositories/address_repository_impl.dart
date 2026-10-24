import 'package:pooja_pasal/features/addresses/data/datasources/address_remote_data_source.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/addresses/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource _dataSource;

  AddressRepositoryImpl(this._dataSource);

  @override
  Stream<List<Address>> streamAddresses(String uid) => _dataSource.streamAddresses(uid);

  @override
  Future<void> add(String uid, Address address) => _dataSource.add(uid, address);

  @override
  Future<void> update(String uid, Address address) => _dataSource.update(uid, address);

  @override
  Future<void> delete(String uid, String addressId) => _dataSource.delete(uid, addressId);

  @override
  Future<void> setDefault(String uid, String addressId) => _dataSource.setDefault(uid, addressId);
}
