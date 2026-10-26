import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';

/// The signed-in user's saved delivery addresses (`/addresses`). The API
/// keeps exactly one default and makes the first address the default.
/// [uid] is implied by the session; it's kept for the repository's shape.
class AddressRemoteDataSource {
  AddressRemoteDataSource(this._api);

  final ApiClient _api;

  Stream<List<Address>> streamAddresses(String uid) => _api.watch(
        {ApiTopics.addresses},
        () async => asJsonList(await _api.get('/addresses'))
            .map(Address.fromJson)
            .toList(),
      );

  Future<void> add(String uid, Address address) async {
    await _api.post('/addresses', address.toJson());
    _api.notifyChanged(const [ApiTopics.addresses]);
  }

  Future<void> update(String uid, Address address) async {
    await _api.put('/addresses/${address.id}', address.toJson());
    _api.notifyChanged(const [ApiTopics.addresses]);
  }

  Future<void> delete(String uid, String addressId) async {
    await _api.delete('/addresses/$addressId');
    _api.notifyChanged(const [ApiTopics.addresses]);
  }

  Future<void> setDefault(String uid, String addressId) async {
    await _api.post('/addresses/$addressId/default');
    _api.notifyChanged(const [ApiTopics.addresses]);
  }
}
