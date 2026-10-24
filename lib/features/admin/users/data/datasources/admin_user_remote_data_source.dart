import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';

class AdminUserRemoteDataSource {
  AdminUserRemoteDataSource(this._api);

  final ApiClient _api;

  Stream<List<AppUser>> streamUsers({int limit = 200}) => _api.watch(
        {ApiTopics.users},
        () async =>
            asJsonList(await _api.get('/admin/users')).map(AppUser.fromJson).take(limit).toList(),
      );
}
