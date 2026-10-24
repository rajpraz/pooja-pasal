import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';

abstract class AdminUserRepository {
  /// All users, most recent first, bounded (not the whole table). No
  /// pagination yet — a known limitation for large user bases.
  Stream<List<AppUser>> streamUsers({int limit});
}
