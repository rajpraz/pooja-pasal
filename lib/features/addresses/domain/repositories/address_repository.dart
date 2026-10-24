import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';

abstract class AddressRepository {
  Stream<List<Address>> streamAddresses(String uid);

  /// If [address.isDefault] is true, unsets `isDefault` on every other
  /// saved address for this user atomically with the write.
  Future<void> add(String uid, Address address);

  Future<void> update(String uid, Address address);

  Future<void> delete(String uid, String addressId);

  Future<void> setDefault(String uid, String addressId);
}
