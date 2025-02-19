class Project {
  final String name;
  final String description;
  final String imageUrl;
  final List<String> technologies;
  final String githubUrl;
  final int stars;

  Project({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.technologies,
    required this.githubUrl,
    required this.stars,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['owner']['avatar_url'] ?? '',
      technologies: List<String>.from(json['topics'] ?? []),
      githubUrl: json['html_url'] ?? '',
      stars: json['stargazers_count'] ?? 0,
    );
  }
}