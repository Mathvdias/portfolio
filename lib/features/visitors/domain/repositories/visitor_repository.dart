import '../../../../core/result/result.dart';

abstract interface class VisitorRepository {
  Future<Result<void>> recordVisit();
  Stream<int> watchVisitorCount();
}
