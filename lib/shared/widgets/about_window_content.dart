import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AboutWindowContent extends StatelessWidget {
  const AboutWindowContent({super.key, required this.bio, required this.role});

  final String bio;
  final String role;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MATHEUS DIAS',
              style: GoogleFonts.pressStart2p(
                fontSize: 12,
                color: AppTheme.blue,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: AppTheme.mauve,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MANAUS, AM — BRAZIL',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: AppTheme.subtext,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.surface0, thickness: 1),
            const SizedBox(height: 16),
            Text(
              bio,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'EDUCATION',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: AppTheme.subtext,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Eng. Elétrica — UniNorte (2019–2023)',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            Text(
              'Téc. Eletrônica — IFAM (2014–2016)',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'INTERESTS',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: AppTheme.subtext,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Game engine (Jetpack Compose)',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            Text(
              'Home lab (Docker + Raspberry Pi)',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
