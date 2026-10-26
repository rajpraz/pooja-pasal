import 'package:pooja_pasal/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:pooja_pasal/features/payments/domain/entities/esewa_initiation.dart';
import 'package:pooja_pasal/features/payments/domain/entities/khalti_initiation.dart';
import 'package:pooja_pasal/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _dataSource;

  PaymentRepositoryImpl(this._dataSource);

  @override
  Future<List<String>> availableMethods() => _dataSource.availableMethods();

  @override
  Future<KhaltiInitiation> initiateKhalti(String orderId) =>
      _dataSource.initiateKhalti(orderId);

  @override
  Future<void> verifyKhalti({required String orderId, required String pidx}) =>
      _dataSource.verifyKhalti(orderId: orderId, pidx: pidx);

  @override
  Future<EsewaInitiation> initiateEsewa(String orderId) =>
      _dataSource.initiateEsewa(orderId);

  @override
  Future<void> verifyEsewa(String orderId) => _dataSource.verifyEsewa(orderId);

  @override
  Future<void> confirmCodPayment(String orderId) =>
      _dataSource.confirmCodPayment(orderId);
}
