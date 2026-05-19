import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/mappers/experience_mapper.dart';
import 'package:portifolio/shared/models/experience.dart';
import 'package:portifolio/shared/models/sdf_shape.dart';
import 'package:portifolio/shared/widgets/sdf_icon.dart';
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

    test('returns peach for unknown', () {
      expect(ExperienceMapper.colorFor('Acme Corp'), AppTheme.peach);
    });
  });

  group('ExperienceMapper.iconWidgetFor', () {
    SdfShape shape(Widget w) => (w as SdfIcon).shape;

    test('returns SdfIcon for every company', () {
      expect(ExperienceMapper.iconWidgetFor('Zallpy'), isA<SdfIcon>());
      expect(ExperienceMapper.iconWidgetFor('Banco Pan'), isA<SdfIcon>());
      expect(ExperienceMapper.iconWidgetFor('Conecthus'), isA<SdfIcon>());
      expect(ExperienceMapper.iconWidgetFor('Oi'), isA<SdfIcon>());
      expect(ExperienceMapper.iconWidgetFor('Acme Corp'), isA<SdfIcon>());
    });

    test('returns briefcase shape for Zallpy', () {
      expect(shape(ExperienceMapper.iconWidgetFor('Zallpy')), SdfShape.briefcase);
    });

    test('returns building shape for Banco Pan', () {
      expect(shape(ExperienceMapper.iconWidgetFor('Banco Pan')), SdfShape.building);
    });

    test('returns wifi shape for Conecthus', () {
      expect(shape(ExperienceMapper.iconWidgetFor('Conecthus')), SdfShape.wifi);
    });

    test('returns phone shape for Oi', () {
      expect(shape(ExperienceMapper.iconWidgetFor('Oi')), SdfShape.phone);
    });

    test('returns building shape for unknown company', () {
      expect(shape(ExperienceMapper.iconWidgetFor('Acme Corp')), SdfShape.building);
    });

    test('correct color for each company', () {
      expect((ExperienceMapper.iconWidgetFor('Zallpy') as SdfIcon).color, AppTheme.teal);
      expect((ExperienceMapper.iconWidgetFor('Banco Pan') as SdfIcon).color, AppTheme.blue);
      expect((ExperienceMapper.iconWidgetFor('Conecthus') as SdfIcon).color, AppTheme.green);
      expect((ExperienceMapper.iconWidgetFor('Oi') as SdfIcon).color, AppTheme.peach);
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
