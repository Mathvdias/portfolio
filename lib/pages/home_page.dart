import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:portifolio/controllers/language_controller.dart' show LanguageController;
import 'package:portifolio/l10n/app_localizations.dart' show AppLocalizations;
import 'package:portifolio/widgets/footer.dart' show Footer;
import 'package:portifolio/widgets/language_selector.dart';
import 'package:portifolio/widgets/parallax_background.dart' show ParallaxBackground;
import 'package:portifolio/widgets/responsive_layout.dart' show ResponsiveLayout;
import 'package:portifolio/widgets/screen_animation.dart' show ScreenAnimation;
import 'package:provider/provider.dart' show Provider;
import 'package:url_launcher/url_launcher.dart' show canLaunchUrl, launchUrl;
import '../models/experience.dart';
import '../models/project.dart';
import '../services/github_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Add to your state class
class _HomePageState extends State<HomePage> {
  String _currentLanguage = 'en';
  
  final GitHubService _githubService = GitHubService();
  final ScrollController _scrollController = ScrollController();
  List<Project> _projects = [];
  final Map<String, GlobalKey> _sectionKeys = {
    'about': GlobalKey(),
    'experience': GlobalKey(),
    'projects': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }



  Future<void> _loadProjects() async {
    try {
      final repos = await _githubService.getRepositories();
      setState(() {
        _projects = repos.map((repo) => Project.fromJson(repo)).toList();
      });
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  void scrollToSection(String section) {
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildExperienceCard(Experience experience) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              experience.company,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              experience.role,
              style: const TextStyle(fontSize: 18, color: AppTheme.secondaryColor),
            ),
            Text(experience.period),
            const SizedBox(height: 8),
            Text(experience.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: experience.technologies
                  .map((tech) => Chip(
                        label: Text(tech),
                        backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildProjectCard(Project project) {
    return InkWell(
      onTap: () async {
        final url = Uri.parse(project.githubUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
      child: Card(
        color: AppTheme.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: project.imageUrl,
                      width: 60,
                      height: 60,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          project.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: project.technologies
                    .map((tech) => Chip(
                          label: Text(tech),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);
    final l10n = AppLocalizations.of(context);
    final experiences = [
      Experience(
        company: l10n.companyName,
        role: l10n.role,
        period: "2021 - Present",
        description: l10n.experienceDescription,
        technologies: ["Flutter", "Dart", "iOS", "Android"],
      ),
    ];

    return ResponsiveLayout(
      child: Scaffold(
        body: Stack(
          children: [
            ParallaxBackground(scrollController: _scrollController),
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: AppTheme.backgroundColor,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText('Hello'),
                          TypewriterAnimatedText('Olá'),
                          TypewriterAnimatedText('Hola'),
                          TypewriterAnimatedText('Bonjour'),
                          TypewriterAnimatedText('こんにちは (Konnichiwa)'),
                          TypewriterAnimatedText('안녕하세요 (Annyeonghaseyo)'),
                          TypewriterAnimatedText('你好 (Nǐ hǎo)'),
                        ],
                        repeatForever: true,
                        pause: const Duration(milliseconds: 1000),
                        displayFullTextOnTap: true,
                      ).animate()
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideY(begin: 1, end: 0, duration: const Duration(milliseconds: 800), curve: Curves.easeOutQuad),
                      if (!ResponsiveLayout.isMobile(context))
                        Row(
                          children: [
                            ...(_sectionKeys.keys.map(
                              (section) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: TextButton(
                                  onPressed: () => scrollToSection(section),
                                  child: Text(
                                    l10n.getSection(section),
                                    style: const TextStyle(color: AppTheme.textColor),
                                  ),
                                ),
                              ),
                            )),
                            LanguageSelector(
                              currentLanguage: languageController.currentLanguage,
                              onLanguageChanged: _onLanguageChanged,
                            ),
                          ],
                        )
    
                    ],
                  ),
                ),
                // Hero section
                SliverToBoxAdapter(
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.getHorizontalPadding(context),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              l10n.hello,
                              textStyle: TextStyle(
                                fontSize: ResponsiveLayout.isDesktop(context) ? 48 : 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              l10n.role,
                              textStyle: TextStyle(
                                fontSize: ResponsiveLayout.isDesktop(context) ? 32 : 24,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ].animate().fade().scale(),
                    ),
                  ),
                ),
                // About section
                SliverToBoxAdapter(
                  child: Container(
                    key: _sectionKeys['about'],
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.getHorizontalPadding(context),
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.about,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.bio,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ].animate().fadeIn().slideX(),
                    ),
                  ),
                ),
                // Experience section
                SliverToBoxAdapter(
                  child: Container(
                    key: _sectionKeys['experience'],
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.getHorizontalPadding(context),
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.experience,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...experiences.map(_buildExperienceCard),
                      ],
                    ),
                  ),
                ),
                // Projects section
                SliverToBoxAdapter(
                  child: Container(
                    key: _sectionKeys['projects'],
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.getHorizontalPadding(context),
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.projects,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_projects.isEmpty)
                          const CircularProgressIndicator()
                        else
                          ..._projects.map(_buildProjectCard),
                      ],
                    ),
                  ),
                ),
                // Footer
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Footer(),
                    ],
                  ),
                ),
              ],
            ),
            ScreenAnimation(scrollController: _scrollController),
          ],
        ),
        endDrawer: ResponsiveLayout.isMobile(context) 
            ? buildMobileDrawer(l10n) 
            : null,
      ),
    );
  }
  // Add this method to handle language changes
  void _onLanguageChanged(String languageCode) {
    final languageController = Provider.of<LanguageController>(context, listen: false);
    setState(() {
      _currentLanguage = languageCode;
    });
    languageController.setLocale(Locale(languageCode));
  }

  // Add this method to build the mobile drawer
  Widget buildMobileDrawer(AppLocalizations l10n) {
    return Drawer(
      child: Container(
        color: AppTheme.backgroundColor,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
              ),
              child: Text(
                l10n.hello,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 24,
                ),
              ),
            ),
            ..._sectionKeys.keys.map(
              (section) => ListTile(
                title: Text(
                  l10n.getSection(section),
                  style: const TextStyle(color: AppTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  scrollToSection(section);
                },
              ),
            ),
            ListTile(
              title: LanguageSelector(
                currentLanguage: _currentLanguage,
                onLanguageChanged: (code) {
                  Navigator.pop(context);
                  _onLanguageChanged(code);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}