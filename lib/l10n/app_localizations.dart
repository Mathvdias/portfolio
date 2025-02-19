import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'hello': 'Hello, I\'m Matheus Dias',
      'role': 'Mobile Developer',
      'about': 'About Me',
      'experience': 'Experience',
      'projects': 'Projects',
      'bio': 'Mobile developer with experience in Flutter and native development. Passionate about creating beautiful and functional applications.',
      'companyName': 'Your Company',
      'experienceDescription': 'Working on mobile applications using Flutter and native technologies.',
    },
    'es': {
      'hello': 'Hola, soy Matheus Dias',
      'role': 'Desarrollador Móvil',
      'about': 'Sobre Mí',
      'experience': 'Experiencia',
      'projects': 'Proyectos',
      'bio': 'Desarrollador móvil con experiencia en Flutter y desarrollo nativo. Apasionado por crear aplicaciones hermosas y funcionales.',
      'companyName': 'Tu Empresa',
      'experienceDescription': 'Trabajando en aplicaciones móviles usando Flutter y tecnologías nativas.',
    },
    'fr': {
      'hello': 'Bonjour, je suis Matheus Dias',
      'role': 'Développeur Mobile',
      'about': 'À Propos',
      'experience': 'Expérience',
      'projects': 'Projets',
      'bio': 'Développeur mobile avec expérience en Flutter et développement natif. Passionné par la création d\'applications belles et fonctionnelles.',
      'companyName': 'Votre Entreprise',
      'experienceDescription': 'Travail sur des applications mobiles utilisant Flutter et les technologies natives.',
    },
    'it': {
      'hello': 'Ciao, sono Matheus Dias',
      'role': 'Sviluppatore Mobile',
      'about': 'Chi Sono',
      'experience': 'Esperienza',
      'projects': 'Progetti',
      'bio': 'Sviluppatore mobile con esperienza in Flutter e sviluppo nativo. Appassionato di creare applicazioni belle e funzionali.',
      'companyName': 'La Tua Azienda',
      'experienceDescription': 'Lavoro su applicazioni mobili utilizzando Flutter e tecnologie native.',
    },
    'pt': {
      'hello': 'Olá, eu sou Matheus Dias',
      'role': 'Desenvolvedor Mobile',
      'about': 'Sobre Mim',
      'experience': 'Experiência',
      'projects': 'Projetos',
      'bio': 'Desenvolvedor mobile com experiência em Flutter e desenvolvimento nativo. Apaixonado por criar aplicativos bonitos e funcionais.',
      'companyName': 'Sua Empresa',
      'experienceDescription': 'Trabalhando em aplicativos móveis usando Flutter e tecnologias nativas.',
    },
  };

  // Add getters for the new strings
  String get companyName => _localizedValues[locale.languageCode]?['companyName'] ?? '';
  String get experienceDescription => _localizedValues[locale.languageCode]?['experienceDescription'] ?? '';

  String get hello => _localizedValues[locale.languageCode]?['hello'] ?? '';
  String get role => _localizedValues[locale.languageCode]?['role'] ?? '';
  String get about => _localizedValues[locale.languageCode]?['about'] ?? '';
  String get experience => _localizedValues[locale.languageCode]?['experience'] ?? '';
  String get projects => _localizedValues[locale.languageCode]?['projects'] ?? '';
  String get bio => _localizedValues[locale.languageCode]?['bio'] ?? '';

  String getSection(String section) {
    switch (section) {
      case 'about':
        return about;
      case 'experience':
        return experience;
      case 'projects':
        return projects;
      default:
        return section;
    }
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'it', 'pt'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}