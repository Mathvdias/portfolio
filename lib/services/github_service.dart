import 'package:http/http.dart' as http;
import 'dart:convert';

class GitHubService {
  final String username = 'Mathvdias';
  final String baseUrl = 'https://api.github.com';

  Future<List<dynamic>> getRepositories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$username/repos'),
      headers: {'Accept': 'application/vnd.github.v3+json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load repositories');
    }
  }
}