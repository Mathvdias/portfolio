import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:portifolio/shared/mappers/experience_mapper.dart';
import 'package:portifolio/shared/models/experience.dart';
import 'package:portifolio/theme/app_theme.dart';

void main() {
  group('ExperienceMapper.fromL10n', () {
    test('parses a well-formed list of maps', () {
      final raw = <Map<String, dynamic>>[
        {
          'company': 'Zallpy Digital',
          'role': 'Engineer',
          'period': '2024–now',
          'description': 'desc',
          'technologies': ['Flutter', 'Dart'],
        },
      ];

      final result = ExperienceMapper.fromL10n(raw);

      expect(result, hasLength(1));
      expect(result[0].company, 'Zallpy Digital');
      expect(result[0].role, 'Engineer');
      expect(result[0].period, '2024–now');
      expect(result[0].description, 'desc');
      expect(result[0].technologies, ['Flutter', 'Dart']);
    });

    test('falls back to empty strings and empty list when keys missing', () {
      final raw = <Map<String, dynamic>>[{}];

      final result = ExperienceMapper.fromL10n(raw);

      expect(result[0].company, '');
      expect(result[0].role, '');
      expect(result[0].period, '');
      expect(result[0].description, '');
      expect(result[0].technologies, isEmpty);
    });

    test('handles empty list', () {
      expect(ExperienceMapper.fromL10n([]), isEmpty);
    });
  });

  group('ExperienceMapper.colorFor', () {
    test('returns teal for Zallpy', () {
      expect(ExperienceMapper.colorFor('Zallpy Digital'), AppTheme.teal);
    });

    test('returns blue for Banco Pan', () {
      expect(ExperienceMapper.colorFor('Banco Pan'), AppTheme.blue);
    });

    test('returns blue for PAN', () {
      expect(ExperienceMapper.colorFor('PAN'), AppTheme.blue);
    });

    test('returns blue for Pan', () {
      expect(ExperienceMapper.colorFor('Pan'), AppTheme.blue);
    });

    test('returns green for Conecthus', () {
      expect(ExperienceMapper.colorFor('Instituto Conecthus'), AppTheme.green);
    });

    test('returns peach for Oi', () {
      expect(ExperienceMapper.colorFor('Oi'), AppTheme.peach);
    });

    test('returns peach for unknown', () {
      expect(ExperienceMapper.colorFor('Acme Corp'), AppTheme.peach);
    });
  });

  group('ExperienceMapper.iconWidgetFor', () {
    int cp(Widget w) => (w as Icon).icon!.codePoint;

    // Zallpy — Mobile Software Engineer (B2B, cross-platform)
    test('returns mobileScreen for Zallpy', () {
      expect(
        cp(ExperienceMapper.iconWidgetFor('Zallpy')),
        Icons.smartphone.codePoint,
      );
    });

    // Banco Pan — Mobile Software Engineer (banking)
    test('returns buildingColumns for Banco Pan', () {
      expect(
        cp(ExperienceMapper.iconWidgetFor('Banco Pan')),
        Icons.account_balance.codePoint,
      );
    });

    test('returns buildingColumns for PAN', () {
      expect(
        cp(ExperienceMapper.iconWidgetFor('PAN')),
        Icons.account_balance.codePoint,
      );
    });

    // Conecthus — Mobile Developer PL (AI/ML, POS kiosks)
    test('returns microchip for Conecthus', () {
      expect(
        cp(ExperienceMapper.iconWidgetFor('Conecthus')),
        Icons.memory.codePoint,
      );
    });

    // Oi — Maintenance Technician (fiber optic, networking)
    test('returns networkWired for Oi', () {
      expect(
        cp(ExperienceMapper.iconWidgetFor('Oi')),
        Icons.router.codePoint,
      );
    });

    test('returns buildingColumns for unknown', () {
      expect(
        cp(ExperienceMapper.iconWidgetFor('Acme Corp')),
        Icons.account_balance.codePoint,
      );
    });
  });

  group('ExperienceMapper.iconAssetFor', () {
    test('returns zallpy path for Zallpy', () {
      expect(
        ExperienceMapper.iconAssetFor('Zallpy Digital'),
        'assets/icons/zallpy.svg',
      );
    });

    test('returns bancoPan path for Banco Pan', () {
      expect(
        ExperienceMapper.iconAssetFor('Banco Pan'),
        'assets/icons/pan.svg',
      );
    });

    test('returns bancoPan path for PAN', () {
      expect(
        ExperienceMapper.iconAssetFor('PAN'),
        'assets/icons/pan.svg',
      );
    });

    test('returns conecthus path for Conecthus', () {
      expect(
        ExperienceMapper.iconAssetFor('Instituto Conecthus'),
        'assets/icons/conecthus.svg',
      );
    });

    test('returns oi path for Oi', () {
      expect(
        ExperienceMapper.iconAssetFor('Oi'),
        'assets/icons/oi.svg',
      );
    });

    test('returns fallback bancoPan path for unknown', () {
      expect(
        ExperienceMapper.iconAssetFor('Acme Corp'),
        'assets/icons/pan.svg',
      );
    });
  });

  group('ExperienceMapper.shortNameFor', () {
    test('returns Zallpy for Zallpy Digital', () {
      expect(ExperienceMapper.shortNameFor('Zallpy Digital'), 'Zallpy');
    });

    test('returns Banco Pan for PAN', () {
      expect(ExperienceMapper.shortNameFor('PAN'), 'Banco Pan');
    });

    test('returns Banco Pan for Pan', () {
      expect(ExperienceMapper.shortNameFor('Pan'), 'Banco Pan');
    });

    test('returns Banco Pan for Banco', () {
      expect(ExperienceMapper.shortNameFor('Banco'), 'Banco Pan');
    });

    test('returns Conecthus for Instituto Conecthus', () {
      expect(ExperienceMapper.shortNameFor('Instituto Conecthus'), 'Conecthus');
    });

    test('returns Oi for Oi', () {
      expect(ExperienceMapper.shortNameFor('Oi'), 'Oi');
    });

    test('returns first word for unknown', () {
      expect(ExperienceMapper.shortNameFor('Acme Corp'), 'Acme');
    });
  });

  group('Experience model', () {
    test('stores all fields correctly', () {
      const exp = Experience(
        company: 'Test',
        role: 'Dev',
        period: '2024',
        description: 'desc',
        technologies: ['A', 'B'],
      );

      expect(exp.company, 'Test');
      expect(exp.role, 'Dev');
      expect(exp.period, '2024');
      expect(exp.description, 'desc');
      expect(exp.technologies, ['A', 'B']);
    });
  });
}
