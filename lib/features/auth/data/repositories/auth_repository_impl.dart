import 'package:pooja_pasal/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';
import 'package:pooja_pasal/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<AuthSession?> authStateChanges() => _dataSource.authStateChanges();

  @override
  AuthSession? get currentUser => _dataSource.currentUser;

  @override
  Stream<AppUser?> userDocStream(String uid) => _dataSource.userDocStream(uid);

  @override
  Future<AppUser?> getUserDoc(String uid) => _dataSource.getUserDoc(uid);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
    String? shopName,
  }) {
    return _dataSource.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
      address: address,
      role: role,
      shopName: shopName,
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _dataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _dataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) {
    return _dataSource.updateUserProfile(
        name: name, phone: phone, address: address, photoUrl: photoUrl);
  }

  @override
  Future<void> applyToSell({required String shopName, required String phone, String? reason}) {
    return _dataSource.applyToSell(shopName: shopName, phone: phone, reason: reason);
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
