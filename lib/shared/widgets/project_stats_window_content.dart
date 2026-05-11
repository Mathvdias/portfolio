
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';

class ProjectStatsWindowContent extends StatelessWidget {
  const ProjectStatsWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    const coverage = 77.30; // We calculated this earlier!
    final color = coverage >= 80 ? AppTheme.green : (coverage >= 60 ? AppTheme.yellow : AppTheme.red);

    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Column(
        children: [
          Text(
            'PROJECT METRICS',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: coverage / 100,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${coverage.toStringAsFixed(1)}%',
                    style: GoogleFonts.spaceMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'COVERAGE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppTheme.subtext,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingLg),
          _buildStatRow('Unit Tests', '115'),
          _buildStatRow('Code Quality', 'A+'),
          _buildStatRow('Build Status', 'Passing'),
          const Spacer(),
          Text(
            'Keep building, keep testing.',
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.subtext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(fontSize: 14, color: AppTheme.subtext),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
