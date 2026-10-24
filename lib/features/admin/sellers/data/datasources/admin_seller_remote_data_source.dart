import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';

/// Admin seller management. Approving an application is what turns a buyer
/// into a seller; the API refuses applications that are no longer pending.
class AdminSellerRemoteDataSource {
  AdminSellerRemoteDataSource(this._api);

  final ApiClient _api;

  static const _changed = [ApiTopics.sellerApplications, ApiTopics.users];

  Stream<List<SellerApplication>> streamPendingApplications() => _api.watch(
        {ApiTopics.sellerApplications},
        () async => asJsonList(await _api.get('/admin/seller-applications'))
            .map(SellerApplication.fromJson)
            .toList(),
      );

  Future<void> approveApplication(String applicantUid) async {
    await _api.post('/admin/seller-applications/$applicantUid/approve');
    _api.notifyChanged(_changed);
  }

  Future<void> rejectApplication(String applicantUid, {String? reason}) async {
    await _api.post('/admin/seller-applications/$applicantUid/reject', {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    _api.notifyChanged(_changed);
  }

  Stream<List<AppUser>> streamSellers() => _api.watch(
        {ApiTopics.users},
        () async => asJsonList(await _api.get('/admin/users', query: {'role': 'seller'}))
            .map(AppUser.fromJson)
            .toList(),
      );

  Future<void> setUserRole(String uid, String role) async {
    await _api.patch('/admin/users/$uid/role', {'role': role});
    _api.notifyChanged(_changed);
  }
}
