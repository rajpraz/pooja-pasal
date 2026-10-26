import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/admin/users/data/datasources/admin_user_remote_data_source.dart';
import 'package:pooja_pasal/features/admin/users/data/repositories/admin_user_repository_impl.dart';
import 'package:pooja_pasal/features/admin/users/domain/repositories/admin_user_repository.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepositoryImpl(
      AdminUserRemoteDataSource(ref.watch(apiClientProvider)));
});

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(adminUserRepositoryProvider).streamUsers();
});
