import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/mappers/experience_mapper.dart';
import 'package:portifolio/shared/models/experience.dart';
import 'package:portifolio/theme/app_theme.dart';
import 'package:flutter/material.dart';

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

    test('returns peach for unknown', () {
      expect(ExperienceMapper.colorFor('Acme Corp'), AppTheme.peach);
    });
  });

  group('ExperienceMapper.iconWidgetFor', () {
    test('returns Icons.business for Zallpy', () {
      final widget = ExperienceMapper.iconWidgetFor('Zallpy') as Icon;
      expect(widget.icon, Icons.business);
    });

    test('returns Icons.account_balance for Banco Pan', () {
      final widget = ExperienceMapper.iconWidgetFor('Banco Pan') as Icon;
      expect(widget.icon, Icons.account_balance);
    });

    test('returns Icons.network_wifi for Conecthus', () {
      final widget = ExperienceMapper.iconWidgetFor('Conecthus') as Icon;
      expect(widget.icon, Icons.network_wifi);
    });

    test('returns Icons.phone for Oi', () {
      final widget = ExperienceMapper.iconWidgetFor('Oi') as Icon;
      expect(widget.icon, Icons.phone);
    });

    test('returns Icons.work for unknown', () {
      final widget = ExperienceMapper.iconWidgetFor('Acme Corp') as Icon;
      expect(widget.icon, Icons.work);
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
