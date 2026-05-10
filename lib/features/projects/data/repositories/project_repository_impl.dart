import '../../../../core/result/result.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/github_datasource.dart';

const _excludedRepos = {'intercepted_http', 'portifolio'};

class ProjectRepositoryImpl implements ProjectRepository {
  const ProjectRepositoryImpl(this._datasource);

  final GitHubDatasource _datasource;

  @override
  Future<Result<List<Project>>> getProjects() async {
    final result = await _datasource.fetchRepositories();

    return result.fold(
      Failure.new,
      (rawList) {
        final projects =
            rawList
                .map(Project.fromJson)
                .where((p) => !_excludedRepos.contains(p.name))
                .toList();
        return Success(projects);
      },
    );
  }
}
