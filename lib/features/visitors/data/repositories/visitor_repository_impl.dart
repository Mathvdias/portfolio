import '../../../../core/result/result.dart';
import '../../domain/repositories/visitor_repository.dart';
import '../datasources/visitor_datasource.dart';

class VisitorRepositoryImpl implements VisitorRepository {
  const VisitorRepositoryImpl(this._datasource);

  final VisitorDatasource _datasource;

  @override
  Future<Result<void>> recordVisit() => _datasource.recordVisit();

  @override
  Stream<int> watchVisitorCount() => _datasource.watchCount();
}
