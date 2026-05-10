import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, dynamic>> _localizedValues = {
    "en": {
      "hello": "Hello, I'm Matheus Dias",
      "role": "Software Engineer",
      "about": "About Me",
      "experience": "Experience",
      "projects": "Projects",
      "name": "Matheus Dias",
      "location": "Manaus, AM",
      "bio":
          "I am a Mobile Software Engineer specializing in Kotlin for Android development, with strong expertise in Flutter for cross-platform applications. I have solid experience in medium-sized mobile projects, contributing from conception to deployment and maintenance.\n\nMy focus is on solving complex problems in mobile development and software engineering, applying data structures and algorithms to optimize performance and scalability. I have experience designing and implementing modular architectures, ensuring code maintainability and efficiency.\n\nMy ability to analyze performance bottlenecks and improve application stability has been fundamental in delivering high-quality software. I am passionate about leveraging technology to create innovative solutions that enhance user experience and add value to products.",
      "companyName": "Your Company",
      "experienceDescription":
          "Developing mobile applications using Kotlin, Flutter, and modern technologies.",
      "stickyNoteTodo": "Todo:\n\n- Build amazing apps\n- Pray 🙏\n\nPhil 4:13",
      "notificationCenter": "Notification Center",
      "dailyVerse": "Daily Verse",
      "dailyVerseText":
          "I can do all things through Christ who strengthens me. - Phil 4:13",
      "system": "System",
      "portfolioUpdated": "Portfolio updated successfully.",
      "musicPlaying": "Regina Caeli Jubila",
      "experiences": [
        {
          "company": "Zallpy Digital / West Shore Solutions",
          "role": "Mobile Software Engineer",
          "period": "Sep 2024 – Present",
          "description":
              "Led the development and refactoring of mobile solutions for global B2B clients, ensuring compliance with WCAG accessibility standards and full i18n support. Implemented Clean Architecture in legacy modules, reducing new engineer onboarding time by 10%. Defined development standards for distributed squads, focusing on long-term performance and maintainability.",
          "technologies": [
            "Flutter",
            "Dart",
            "Kotlin",
            "Clean Architecture",
            "WCAG",
            "i18n",
            "B2B",
          ],
        },
        {
          "company": "Banco Pan",
          "role": "Mobile Software Engineer",
          "period": "Jan 2024 – Aug 2024",
          "description":
              "Led the modularization of DSKit components to enhance efficiency and maintainability. Analyzed Crashlytics data to identify and resolve performance and stability issues. Managed versioning and incident tracking in production to ensure high product quality.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Android",
            "iOS",
            "Crashlytics",
            "Testing",
          ],
        },
        {
          "company":
              "Instituto Conecthus - Tecnologia e Biotecnologia do Amazonas",
          "role": "Mobile Developer PL",
          "period": "Aug 2021 – Nov 2023",
          "description":
              "Developed cross-platform mobile applications using Flutter with modern UI/UX. Integrated native Android features with Kotlin and Java for performance optimization. Designed POS and self-service kiosk solutions, integrating AI and machine learning for automated processes.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Java",
            "Android",
            "POS",
            "TensorFlow Lite",
            "ML Kit",
            "Scrum",
            "Kanban",
          ],
        },
        {
          "company": "Oi",
          "role": "Maintenance Technician",
          "period": "Aug 2019 - Jul 2021",
          "description":
              "Managed fiber optic network maintenance at a national scale to ensure service stability. Developed Java-based applications for Huawei router configuration. Conducted SQL database maintenance and troubleshooting.",
          "technologies": ["Java", "SQL", "Networking", "Huawei Routers"],
        },
      ],
    },
    "es": {
      "hello": "Hola, soy Matheus Dias",
      "role": "Ingeniero de Software",
      "about": "Sobre Mí",
      "experience": "Experiencia",
      "projects": "Proyectos",
      "name": "Matheus Dias",
      "location": "Manaus, AM",
      "bio":
          "Soy un Ingeniero de Software Móvil especializado en Kotlin para desarrollo Android, con amplia experiencia en Flutter para aplicaciones multiplataforma. Tengo un historial sólido en proyectos móviles de tamaño medio, participando en todas las etapas, desde la concepción hasta el lanzamiento y mantenimiento.\n\nMi enfoque está en la resolución de problemas complejos en el desarrollo móvil y la ingeniería de software, aplicando estructuras de datos y algoritmos para optimizar el rendimiento y la escalabilidad. Tengo experiencia en el diseño e implementación de arquitecturas modulares, garantizando la mantenibilidad y eficiencia del código.\n\nMi capacidad para analizar cuellos de botella de rendimiento y mejorar la estabilidad de las aplicaciones ha sido fundamental para la entrega de software de alta calidad. Me apasiona aprovechar la tecnología para crear soluciones innovadoras que mejoren la experiencia del usuario y agreguen valor a los productos.",
      "companyName": "Tu Empresa",
      "experienceDescription":
          "Desarrollando aplicaciones móviles con Kotlin, Flutter y tecnologías modernas.",
      "stickyNoteTodo":
          "Todo:\n\n- Crear apps increíbles\n- Rezar 🙏\n\nDe mil soldados não teme a espada quem pugna à sombra da Imaculada!",
      "notificationCenter": "Centro de Notificaciones",
      "dailyVerse": "Versículo Diario",
      "dailyVerseText": "Todo lo puedo en Cristo que me fortalece. - Fil 4:13",
      "system": "Sistema",
      "portfolioUpdated": "Portafolio actualizado con éxito.",
      "musicPlaying": "Regina Caeli Jubila",
      "experiences": [
        {
          "company": "Zallpy Digital / West Shore Solutions",
          "role": "Ingeniero de Software Móvil",
          "period": "Sep 2024 – Presente",
          "description":
              "Liderazgo en proyecto internacional (B2B): desarrollo y refactorización de soluciones móviles para clientes globales, garantizando conformidad con estándares WCAG de accesibilidad y soporte completo de i18n. Implementación de Clean Architecture en módulos legados, reduciendo en un 10% el tiempo de integración de nuevos ingenieros.",
          "technologies": [
            "Flutter",
            "Dart",
            "Kotlin",
            "Clean Architecture",
            "WCAG",
            "i18n",
            "B2B",
          ],
        },
        {
          "company": "Banco Pan",
          "role": "Ingeniero de Software Móvil",
          "period": "Ene 2024 – Ago 2024",
          "description":
              "Lideré la modularización de componentes DSKit para mejorar la eficiencia y el mantenimiento. Analicé datos de Crashlytics para identificar y resolver problemas de rendimiento y estabilidad. Gestioné el versionado y el seguimiento de incidentes en producción para garantizar la alta calidad del producto.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Android",
            "iOS",
            "Crashlytics",
            "Testing",
          ],
        },
        {
          "company":
              "Instituto Conecthus - Tecnología y Biotecnología del Amazonas",
          "role": "Desarrollador Móvil PL",
          "period": "Ago 2021 – Nov 2023",
          "description":
              "Desarrollé aplicaciones móviles multiplataforma utilizando Flutter con UI/UX modernas. Integré características nativas de Android con Kotlin y Java para optimizar el rendimiento. Diseñé soluciones POS y quioscos de autoservicio, integrando IA y aprendizaje automático.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Java",
            "Android",
            "POS",
            "TensorFlow Lite",
            "ML Kit",
            "Scrum",
            "Kanban",
          ],
        },
        {
          "company": "Oi",
          "role": "Técnico de Mantenimiento",
          "period": "Ago 2019 - Jul 2021",
          "description":
              "Gestioné el mantenimiento de la red de fibra óptica a nivel nacional para garantizar la estabilidad del servicio. Desarrollé aplicaciones en Java para la configuración de routers Huawei. Realicé mantenimiento y solución de problemas en bases de datos SQL.",
          "technologies": ["Java", "SQL", "Redes", "Routers Huawei"],
        },
      ],
    },
    "fr": {
      "hello": "Bonjour, je suis Matheus Dias",
      "role": "Ingénieur Logiciel",
      "about": "À Propos",
      "experience": "Expérience",
      "projects": "Projets",
      "name": "Matheus Dias",
      "location": "Manaus, AM",
      "bio":
          "Je suis un Ingénieur Logiciel Mobile spécialisé en Kotlin pour le développement Android, avec une solide expertise en Flutter pour les applications multiplateformes. J'ai une expérience avérée dans des projets mobiles de taille moyenne, de la conception au déploiement et à la maintenance.\n\nMon objectif est de résoudre des problèmes complexes dans le développement mobile et l'ingénierie logicielle, en appliquant des structures de données et des algorithmes pour optimiser les performances et la scalabilité. J'ai de l'expérience dans la conception et la mise en œuvre d'architectures modulaires, garantissant la maintenabilité et l'efficacité du code.\n\nMa capacité à analyser les goulots d'étranglement des performances et à améliorer la stabilité des applications a été essentielle pour fournir un logiciel de haute qualité. Je suis passionné par l'utilisation de la technologie pour créer des solutions innovantes qui améliorent l'expérience utilisateur et ajoutent de la valeur aux produits.",
      "companyName": "Votre Entreprise",
      "experienceDescription":
          "Développement d'applications mobiles avec Kotlin, Flutter et technologies modernes.",
      "stickyNoteTodo":
          "Todo:\n\n- Créer des apps géniales\n- Prier 🙏\n\nPhil 4:13",
      "notificationCenter": "Centre de Notifications",
      "dailyVerse": "Verset Quotidien",
      "dailyVerseText": "Je puis tout par celui qui me fortifie. - Phil 4:13",
      "system": "Système",
      "portfolioUpdated": "Portfolio mis à jour avec succès.",
      "musicPlaying": "Regina Caeli Jubila",
      "experiences": [
        {
          "company": "Zallpy Digital / West Shore Solutions",
          "role": "Ingénieur Logiciel Mobile",
          "period": "Sep 2024 – Présent",
          "description":
              "Leadership dans un projet international (B2B) : développement et refactorisation de solutions mobiles pour des clients mondiaux, garantissant la conformité aux normes WCAG et le support complet i18n. Implémentation de Clean Architecture dans des modules hérités, réduisant de 10% le temps d'intégration des nouveaux ingénieurs.",
          "technologies": [
            "Flutter",
            "Dart",
            "Kotlin",
            "Clean Architecture",
            "WCAG",
            "i18n",
            "B2B",
          ],
        },
        {
          "company": "Banco Pan",
          "role": "Ingénieur Logiciel Mobile",
          "period": "Jan 2024 – Août 2024",
          "description":
              "J'ai dirigé la modularisation des composants DSKit pour améliorer l'efficacité et la maintenance. J'ai analysé les données Crashlytics pour identifier et résoudre les problèmes de performance et de stabilité. J'ai géré le versionnement et le suivi des incidents en production pour assurer une haute qualité du produit.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Android",
            "iOS",
            "Crashlytics",
            "Testing",
          ],
        },
        {
          "company":
              "Instituto Conecthus - Technologie et Biotechnologie de l'Amazonas",
          "role": "Développeur Mobile PL",
          "period": "Août 2021 – Nov 2023",
          "description":
              "J'ai développé des applications mobiles multiplateformes en utilisant Flutter avec une UI/UX moderne. J'ai intégré des fonctionnalités natives Android avec Kotlin et Java pour optimiser les performances. J'ai conçu des solutions POS et des kiosques en libre-service, en intégrant l'IA et l'apprentissage automatique.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Java",
            "Android",
            "POS",
            "TensorFlow Lite",
            "ML Kit",
            "Scrum",
            "Kanban",
          ],
        },
        {
          "company": "Oi",
          "role": "Technicien de Maintenance",
          "period": "Août 2019 - Juil 2021",
          "description":
              "J'ai géré la maintenance du réseau de fibre optique à l'échelle nationale pour assurer la stabilité du service. J'ai développé des applications en Java pour la configuration des routeurs Huawei. J'ai effectué la maintenance et le dépannage des bases de données SQL.",
          "technologies": ["Java", "SQL", "Réseaux", "Routeurs Huawei"],
        },
      ],
    },
    "it": {
      "hello": "Ciao, sono Matheus Dias",
      "role": "Ingegnere del Software",
      "about": "Chi Sono",
      "experience": "Esperienza",
      "projects": "Progetti",
      "name": "Matheus Dias",
      "location": "Manaus, AM",
      "bio":
          "Sono un Ingegnere del Software Mobile, specializzato in Kotlin per lo sviluppo Android e con una forte esperienza in Flutter per applicazioni multipiattaforma. Ho una solida esperienza in progetti mobili di medie dimensioni, dalla concezione al rilascio e alla manutenzione.\n\nIl mio obiettivo è risolvere problemi complessi nello sviluppo mobile e nell'ingegneria del software, applicando strutture dati e algoritmi per ottimizzare le prestazioni e la scalabilità. Ho esperienza nella progettazione e implementazione di architetture modulari, garantendo la manutenibilità e l'efficienza del codice.\n\nLa mia capacità di analizzare i colli di bottiglia delle prestazioni e migliorare la stabilità delle applicazioni è stata essenziale per fornire software di alta qualità. Sono appassionato dell'uso della tecnologia per creare soluzioni innovative che migliorano l'esperienza utente e aggiungono valore ai prodotti.",
      "companyName": "La Tua Azienda",
      "experienceDescription":
          "Sviluppo di applicazioni mobili con Kotlin, Flutter e tecnologie moderne.",
      "stickyNoteTodo":
          "Todo:\n\n- Creare app fantastiche\n- Pregare 🙏\n\nFil 4:13",
      "notificationCenter": "Centro Notifiche",
      "dailyVerse": "Versetto Quotidiano",
      "dailyVerseText": "Tutto posso in colui che mi dà forza. - Fil 4:13",
      "system": "Sistema",
      "portfolioUpdated": "Portfolio aggiornato con successo.",
      "musicPlaying": "Regina Caeli Jubila",
      "experiences": [
        {
          "company": "Zallpy Digital / West Shore Solutions",
          "role": "Ingegnere del Software Mobile",
          "period": "Set 2024 – Presente",
          "description":
              "Leadership in un progetto internazionale (B2B): sviluppo e refactoring di soluzioni mobile per clienti globali, garantendo la conformità agli standard WCAG di accessibilità e il supporto completo all'i18n. Implementazione di Clean Architecture in moduli legacy, riducendo del 10% il tempo di integrazione dei nuovi ingegneri.",
          "technologies": [
            "Flutter",
            "Dart",
            "Kotlin",
            "Clean Architecture",
            "WCAG",
            "i18n",
            "B2B",
          ],
        },
        {
          "company": "Banco Pan",
          "role": "Ingegnere del Software Mobile",
          "period": "Gen 2024 – Ago 2024",
          "description":
              "Ho guidato la modularizzazione dei componenti DSKit per migliorare l'efficienza e la manutenzione. Ho analizzato i dati di Crashlytics per identificare e risolvere problemi di prestazioni e stabilità. Ho gestito il versionamento e il monitoraggio degli incidenti in produzione per garantire un'alta qualità del prodotto.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Android",
            "iOS",
            "Crashlytics",
            "Testing",
          ],
        },
        {
          "company":
              "Instituto Conecthus - Tecnologia e Biotecnologia dell'Amazzonia",
          "role": "Sviluppatore Mobile PL",
          "period": "Ago 2021 – Nov 2023",
          "description":
              "Ho sviluppato applicazioni mobili multipiattaforma utilizzando Flutter con un'interfaccia utente moderna. Ho integrato funzionalità native di Android con Kotlin e Java per ottimizzare le prestazioni. Ho progettato soluzioni POS e chioschi self-service, integrando IA e apprendimento automatico.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Java",
            "Android",
            "POS",
            "TensorFlow Lite",
            "ML Kit",
            "Scrum",
            "Kanban",
          ],
        },
        {
          "company": "Oi",
          "role": "Tecnico di Manutenzione",
          "period": "Ago 2019 - Lug 2021",
          "description":
              "Ho gestito la manutenzione della rete in fibra ottica a livello nazionale per garantire la stabilità del servizio. Ho sviluppato applicazioni in Java per la configurazione dei router Huawei. Ho eseguito manutenzione e risoluzione dei problemi nei database SQL.",
          "technologies": ["Java", "SQL", "Reti", "Router Huawei"],
        },
      ],
    },
    "pt": {
      "hello": "Olá, eu sou Matheus Dias",
      "role": "Engenheiro de Software",
      "about": "Sobre Mim",
      "experience": "Experiência",
      "projects": "Projetos",
      "name": "Matheus Dias",
      "location": "Manaus, AM",
      "bio":
          "Sou um Engenheiro de Software Mobile especializado em Kotlin para desenvolvimento Android, com forte experiência também em Flutter para criação de aplicações multiplataforma. Tenho um histórico sólido no desenvolvimento de aplicações móveis de médio porte, atuando desde a concepção até a implantação e manutenção.\n\nMeu foco está na resolução de problemas complexos na área de desenvolvimento mobile e engenharia de software, aplicando estruturas de dados e algoritmos para otimizar desempenho e escalabilidade. Tenho experiência na criação e implementação de arquiteturas modulares, garantindo a manutenção e eficiência do código.\n\nMinha capacidade de analisar gargalos de desempenho e aprimorar a estabilidade das aplicações tem sido fundamental na entrega de software de alta qualidade. Sou apaixonado por utilizar tecnologia para criar soluções inovadoras que melhoram a experiência do usuário e agregam valor aos produtos.",
      "companyName": "Sua Empresa",
      "experienceDescription":
          "Desenvolvendo aplicativos móveis com Kotlin, Flutter e tecnologias modernas.",
      "stickyNoteTodo":
          "Todo:\n\n- Construir apps incríveis\n- Rezar 🙏\n\nFl 4:13",
      "notificationCenter": "Central de Notificações",
      "dailyVerse": "Versículo Diário",
      "dailyVerseText":
          "De mil soldados não teme a espada quem pugna à sombra da Imaculada!",
      "system": "Sistema",
      "portfolioUpdated": "Portfólio atualizado com sucesso.",
      "musicPlaying": "Regina Caeli Jubila",
      "experiences": [
        {
          "company": "Zallpy Digital / West Shore Solutions",
          "role": "Engenheiro de Software Mobile",
          "period": "Set 2024 – Atual",
          "description":
              "Liderança em projeto internacional (B2B): desenvolvimento e refatoração de soluções mobile para clientes globais, garantindo conformidade com padrões WCAG de acessibilidade e suporte completo a i18n. Implementação de Clean Architecture em módulos legados, reduzindo em 10% o tempo de integração de novos engenheiros. Definição de padrões de desenvolvimento para squads distribuídas.",
          "technologies": [
            "Flutter",
            "Dart",
            "Kotlin",
            "Clean Architecture",
            "WCAG",
            "i18n",
            "B2B",
          ],
        },
        {
          "company": "Banco Pan",
          "role": "Engenheiro de Software Mobile",
          "period": "Jan 2024 – Ago 2024",
          "description":
              "Lidero a modularização dos componentes DSKit para melhorar a eficiência e a manutenção. Analiso dados do Crashlytics para identificar e corrigir problemas de desempenho e estabilidade. Gerencio versões e rastreamento de incidentes em produção para garantir alta qualidade do produto.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Android",
            "iOS",
            "Crashlytics",
            "Testing",
          ],
        },
        {
          "company":
              "Instituto Conecthus - Tecnologia e Biotecnologia do Amazonas",
          "role": "Desenvolvedor Mobile PL",
          "period": "Ago 2021 – Nov 2023",
          "description":
              "Desenvolvi aplicativos móveis multiplataforma utilizando Flutter com UI/UX moderna. Integrei funcionalidades nativas do Android com Kotlin e Java para otimizar o desempenho. Projetei soluções POS e totens de autoatendimento, integrando IA e aprendizado de máquina.",
          "technologies": [
            "Flutter",
            "Kotlin",
            "Java",
            "Android",
            "POS",
            "TensorFlow Lite",
            "ML Kit",
            "Scrum",
            "Kanban",
          ],
        },
        {
          "company": "Oi",
          "role": "Técnico de Manutenção",
          "period": "Ago 2019 - Jul 2021",
          "description":
              "Gerenciei a manutenção da rede de fibra óptica em nível nacional para garantir a estabilidade do serviço. Desenvolvi aplicativos em Java para configuração de roteadores Huawei. Realizei manutenção e resolução de problemas em bancos de dados SQL.",
          "technologies": ["Java", "SQL", "Redes", "Roteadores Huawei"],
        },
      ],
    },
  };

  String get hello => _localizedValues[locale.languageCode]?['hello'] ?? '';
  String get role => _localizedValues[locale.languageCode]?['role'] ?? '';
  String get about => _localizedValues[locale.languageCode]?['about'] ?? '';
  String get experience =>
      _localizedValues[locale.languageCode]?['experience'] ?? '';
  String get projects =>
      _localizedValues[locale.languageCode]?['projects'] ?? '';
  String get bio => _localizedValues[locale.languageCode]?['bio'] ?? '';
  String get companyName =>
      _localizedValues[locale.languageCode]?['companyName'] ?? '';
  String get experienceDescription =>
      _localizedValues[locale.languageCode]?['experienceDescription'] ?? '';
  String get name => _localizedValues[locale.languageCode]?['name'] ?? '';
  String get location =>
      _localizedValues[locale.languageCode]?['location'] ?? '';

  String get stickyNoteTodo =>
      _localizedValues[locale.languageCode]?['stickyNoteTodo'] ?? '';
  String get notificationCenter =>
      _localizedValues[locale.languageCode]?['notificationCenter'] ?? '';
  String get dailyVerse =>
      _localizedValues[locale.languageCode]?['dailyVerse'] ?? '';
  String get dailyVerseText =>
      _localizedValues[locale.languageCode]?['dailyVerseText'] ?? '';
  String get system => _localizedValues[locale.languageCode]?['system'] ?? '';
  String get portfolioUpdated =>
      _localizedValues[locale.languageCode]?['portfolioUpdated'] ?? '';
  String get musicPlaying =>
      _localizedValues[locale.languageCode]?['musicPlaying'] ?? '';

  List<Map<String, dynamic>> get experiences {
    final list =
        _localizedValues[locale.languageCode]?['experiences'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

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
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
