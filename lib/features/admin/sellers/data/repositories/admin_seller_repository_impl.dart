import 'package:pooja_pasal/features/admin/sellers/data/datasources/admin_seller_remote_data_source.dart';
import 'package:pooja_pasal/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:pooja_pasal/features/admin/sellers/domain/repositories/admin_seller_repository.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';

class AdminSellerRepositoryImpl implements AdminSellerRepository {
  final AdminSellerRemoteDataSource _dataSource;

  AdminSellerRepositoryImpl(this._dataSource);

  @override
  Stream<List<SellerApplication>> streamPendingApplications() =>
      _dataSource.streamPendingApplications();

  @override
  Future<void> approveApplication(String applicantUid) =>
      _dataSource.approveApplication(applicantUid);

  @override
  Future<void> rejectApplication(String applicantUid, {String? reason}) =>
      _dataSource.rejectApplication(applicantUid, reason: reason);

  @override
  Stream<List<AppUser>> streamSellers() => _dataSource.streamSellers();

  @override
  Future<void> setUserRole(String uid, String role) =>
      _dataSource.setUserRole(uid, role);
}
