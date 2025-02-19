import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    "en": {
      "hello": "Hello, I'm Matheus Dias",
      "role": "Software Engineer",
      "about": "About Me",
      "experience": "Experience",
      "projects": "Projects",
      "bio":
          "I am a Mobile Software Engineer specializing in Kotlin for Android development, with strong expertise in Flutter for cross-platform applications. I have solid experience in medium-sized mobile projects, contributing from conception to deployment and maintenance.\n\nMy focus is on solving complex problems in mobile development and software engineering, applying data structures and algorithms to optimize performance and scalability. I have experience designing and implementing modular architectures, ensuring code maintainability and efficiency.\n\nMy ability to analyze performance bottlenecks and improve application stability has been fundamental in delivering high-quality software. I am passionate about leveraging technology to create innovative solutions that enhance user experience and add value to products.",
      "companyName": "Your Company",
      "experienceDescription":
          "Developing mobile applications using Kotlin, Flutter, and modern technologies.",
    },
    "es": {
      "hello": "Hola, soy Matheus Dias",
      "role": "Ingeniero de Software",
      "about": "Sobre Mí",
      "experience": "Experiencia",
      "projects": "Proyectos",
      "bio":
          "Soy un Ingeniero de Software Móvil especializado en Kotlin para desarrollo Android, con amplia experiencia en Flutter para aplicaciones multiplataforma. Tengo un historial sólido en proyectos móviles de tamaño medio, participando en todas las etapas, desde la concepción hasta el lanzamiento y mantenimiento.\n\nMi enfoque está en la resolución de problemas complejos en el desarrollo móvil y la ingeniería de software, aplicando estructuras de datos y algoritmos para optimizar el rendimiento y la escalabilidad. Tengo experiencia en el diseño e implementación de arquitecturas modulares, garantizando la mantenibilidad y eficiencia del código.\n\nMi capacidad para analizar cuellos de botella de rendimiento y mejorar la estabilidad de las aplicaciones ha sido fundamental para la entrega de software de alta calidad. Me apasiona aprovechar la tecnología para crear soluciones innovadoras que mejoren la experiencia del usuario y agreguen valor a los productos.",
      "companyName": "Tu Empresa",
      "experienceDescription":
          "Desarrollando aplicaciones móviles con Kotlin, Flutter y tecnologías modernas.",
    },
    "fr": {
      "hello": "Bonjour, je suis Matheus Dias",
      "role": "Ingénieur Logiciel",
      "about": "À Propos",
      "experience": "Expérience",
      "projects": "Projets",
      "bio":
          "Je suis un Ingénieur Logiciel Mobile spécialisé en Kotlin pour le développement Android, avec une solide expertise en Flutter pour les applications multiplateformes. J’ai une expérience avérée dans des projets mobiles de taille moyenne, de la conception au déploiement et à la maintenance.\n\nMon objectif est de résoudre des problèmes complexes dans le développement mobile et l’ingénierie logicielle, en appliquant des structures de données et des algorithmes pour optimiser les performances et la scalabilité. J’ai de l’expérience dans la conception et la mise en œuvre d’architectures modulaires, garantissant la maintenabilité et l’efficacité du code.\n\nMa capacité à analyser les goulots d’étranglement des performances et à améliorer la stabilité des applications a été essentielle pour fournir un logiciel de haute qualité. Je suis passionné par l’utilisation de la technologie pour créer des solutions innovantes qui améliorent l’expérience utilisateur et ajoutent de la valeur aux produits.",
      "companyName": "Votre Entreprise",
      "experienceDescription":
          "Développement d'applications mobiles avec Kotlin, Flutter et technologies modernes.",
    },
    "it": {
      "hello": "Ciao, sono Matheus Dias",
      "role": "Ingegnere del Software",
      "about": "Chi Sono",
      "experience": "Esperienza",
      "projects": "Progetti",
      "bio":
          "Sono un Ingegnere del Software Mobile, specializzato in Kotlin per lo sviluppo Android e con una forte esperienza in Flutter per applicazioni multipiattaforma. Ho una solida esperienza in progetti mobili di medie dimensioni, dalla concezione al rilascio e alla manutenzione.\n\nIl mio obiettivo è risolvere problemi complessi nello sviluppo mobile e nell'ingegneria del software, applicando strutture dati e algoritmi per ottimizzare le prestazioni e la scalabilità. Ho esperienza nella progettazione e implementazione di architetture modulari, garantendo la manutenibilità e l’efficienza del codice.\n\nLa mia capacità di analizzare i colli di bottiglia delle prestazioni e migliorare la stabilità delle applicazioni è stata essenziale per fornire software di alta qualità. Sono appassionato dell'uso della tecnologia per creare soluzioni innovative che migliorano l’esperienza utente e aggiungono valore ai prodotti.",
      "companyName": "La Tua Azienda",
      "experienceDescription":
          "Sviluppo di applicazioni mobili con Kotlin, Flutter e tecnologie moderne.",
    },
    "pt": {
      "hello": "Olá, eu sou Matheus Dias",
      "role": "Engenheiro de Software",
      "about": "Sobre Mim",
      "experience": "Experiência",
      "projects": "Projetos",
      "bio":
          "Sou um Engenheiro de Software Mobile especializado em Kotlin para desenvolvimento Android, com forte experiência também em Flutter para criação de aplicações multiplataforma. Tenho um histórico sólido no desenvolvimento de aplicações móveis de médio porte, atuando desde a concepção até a implantação e manutenção.\n\nMeu foco está na resolução de problemas complexos na área de desenvolvimento mobile e engenharia de software, aplicando estruturas de dados e algoritmos para otimizar desempenho e escalabilidade. Tenho experiência na criação e implementação de arquiteturas modulares, garantindo a manutenção e eficiência do código.\n\nMinha capacidade de analisar gargalos de desempenho e aprimorar a estabilidade das aplicações tem sido fundamental na entrega de software de alta qualidade. Sou apaixonado por utilizar tecnologia para criar soluções inovadoras que melhoram a experiência do usuário e agregam valor aos produtos.",
      "companyName": "Sua Empresa",
      "experienceDescription":
          "Desenvolvendo aplicativos móveis com Kotlin, Flutter e tecnologias modernas.",
    },
  };

  // Add getters for the new strings
  String get companyName =>
      _localizedValues[locale.languageCode]?['companyName'] ?? '';
  String get experienceDescription =>
      _localizedValues[locale.languageCode]?['experienceDescription'] ?? '';

  String get hello => _localizedValues[locale.languageCode]?['hello'] ?? '';
  String get role => _localizedValues[locale.languageCode]?['role'] ?? '';
  String get about => _localizedValues[locale.languageCode]?['about'] ?? '';
  String get experience =>
      _localizedValues[locale.languageCode]?['experience'] ?? '';
  String get projects =>
      _localizedValues[locale.languageCode]?['projects'] ?? '';
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
