import 'package:pooja_pasal/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';

abstract class AdminSellerRepository {
  /// Seller applications waiting for review.
  Stream<List<SellerApplication>> streamPendingApplications();

  /// Approving is the only way a buyer becomes a seller; the API refuses
  /// an application that is no longer pending.
  Future<void> approveApplication(String applicantUid);

  Future<void> rejectApplication(String applicantUid, {String? reason});

  /// Every user with `role == 'seller'`.
  Stream<List<AppUser>> streamSellers();

  /// Promotes/demotes any user's role (`PATCH /admin/users/{id}/role`,
  /// admin-only; an admin can't remove their own admin access). Used both
  /// to demote a seller back to buyer ("deactivate" — there is no separate
  /// suspension flag, this genuinely changes their role) and, from the
  /// user-management screen, to promote a buyer to admin.
  Future<void> setUserRole(String uid, String role);
}
