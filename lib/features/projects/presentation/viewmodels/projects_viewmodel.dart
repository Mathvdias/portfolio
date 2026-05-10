import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

enum ProjectsStatus { idle, loading, success, failure }

class ProjectsViewModel extends ChangeNotifier {
  ProjectsViewModel(this._repository);

  final ProjectRepository _repository;

  ProjectsStatus _status = ProjectsStatus.idle;
  List<Project> _projects = [];
  AppFailure? _failure;

  ProjectsStatus get status => _status;
  List<Project> get projects => _projects;
  AppFailure? get failure => _failure;
  bool get isLoading => _status == ProjectsStatus.loading;

  Future<void> load() async {
    if (_status == ProjectsStatus.loading) return;
    _status = ProjectsStatus.loading;
    _failure = null;
    notifyListeners();

    final result = await _repository.getProjects();
    result.fold(
      (failure) {
        _failure = failure;
        _status = ProjectsStatus.failure;
      },
      (projects) {
        _projects = projects;
        _status = ProjectsStatus.success;
      },
    );

    notifyListeners();
  }
}
