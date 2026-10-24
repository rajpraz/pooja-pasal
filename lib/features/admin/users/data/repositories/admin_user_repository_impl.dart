import 'package:pooja_pasal/features/admin/users/data/datasources/admin_user_remote_data_source.dart';
import 'package:pooja_pasal/features/admin/users/domain/repositories/admin_user_repository.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';

class AdminUserRepositoryImpl implements AdminUserRepository {
  final AdminUserRemoteDataSource _dataSource;

  AdminUserRepositoryImpl(this._dataSource);

  @override
  Stream<List<AppUser>> streamUsers({int limit = 200}) => _dataSource.streamUsers(limit: limit);
}
