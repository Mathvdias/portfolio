import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/result.dart';

class GitHubDatasource {
  GitHubDatasource({http.Client? client}) : _client = client ?? http.Client();

  static const _username = 'Mathvdias';
  static const _baseUrl = 'https://api.github.com';

  final http.Client _client;

  Future<Result<List<Map<String, dynamic>>>> fetchRepositories() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/users/$_username/repos'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        return Success(list.cast<Map<String, dynamic>>());
      }

      return Failure(
        ServerFailure('GitHub API returned ${response.statusCode}'),
      );
    } catch (e) {
      return Failure(NetworkFailure('Failed to reach GitHub: $e'));
    }
  }
}
