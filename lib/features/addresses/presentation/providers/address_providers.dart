import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/addresses/data/datasources/address_remote_data_source.dart';
import 'package:pooja_pasal/features/addresses/data/repositories/address_repository_impl.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/addresses/domain/repositories/address_repository.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepositoryImpl(AddressRemoteDataSource(ref.watch(apiClientProvider)));
});

/// Live saved-address list for one signed-in user. Mirrors `cartProvider`/
/// `wishlistProvider`'s per-uid `StreamProvider.family` shape.
final addressesProvider = StreamProvider.family<List<Address>, String>((ref, uid) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(addressRepositoryProvider).streamAddresses(uid);
});

/// Wraps address mutations so widgets never call the API directly.
class AddressController extends AsyncNotifier<void> {
  late final AddressRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(addressRepositoryProvider);
  }

  Future<void> add(String uid, Address address) async {
    state = const AsyncLoading();
    try {
      await _repository.add(uid, address);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAddress(String uid, Address address) async {
    state = const AsyncLoading();
    try {
      await _repository.update(uid, address);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> delete(String uid, String addressId) async {
    state = const AsyncLoading();
    try {
      await _repository.delete(uid, addressId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setDefault(String uid, String addressId) async {
    state = const AsyncLoading();
    try {
      await _repository.setDefault(uid, addressId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final addressControllerProvider =
    AsyncNotifierProvider<AddressController, void>(AddressController.new);
