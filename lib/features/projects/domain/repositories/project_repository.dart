import '../../../../core/result/result.dart';
import '../entities/project.dart';

abstract interface class ProjectRepository {
  Future<Result<List<Project>>> getProjects();
}
