class Project {
  const Project({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.technologies,
    required this.githubUrl,
    required this.stars,
  });

  final String name;
  final String description;
  final String imageUrl;
  final List<String> technologies;
  final String githubUrl;
  final int stars;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl:
          (json['owner'] as Map<String, dynamic>?)?['avatar_url'] as String? ??
          '',
      technologies: List<String>.from(json['topics'] as List? ?? []),
      githubUrl: json['html_url'] as String? ?? '',
      stars: json['stargazers_count'] as int? ?? 0,
    );
  }
}
