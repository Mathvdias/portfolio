import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

class ContactFormContent extends StatefulWidget {
  const ContactFormContent({super.key});

  @override
  State<ContactFormContent> createState() => _ContactFormContentState();
}

class _ContactFormContentState extends State<ContactFormContent> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppStrings.emailRaw,
      queryParameters: {'subject': _subjectCtrl.text, 'body': _bodyCtrl.text},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: SizedBox(
          height: 300, // Give it a fixed height inside the window
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.contactNewMessage,
                style: GoogleFonts.spaceMono(
                  fontSize: AppSizes.font3xl,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: AppSizes.spacingXl),
              TextField(
                controller: _subjectCtrl,
                style: GoogleFonts.spaceMono(
                  color: AppTheme.text,
                  fontSize: AppSizes.fontXxl,
                ),
                decoration: const InputDecoration(
                  labelText: AppStrings.contactSubject,
                  labelStyle: TextStyle(color: AppTheme.subtext),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.surface0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.blue),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingLg),
              Expanded(
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.text,
                    fontSize: AppSizes.fontXxl,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.contactMessage,
                    labelStyle: TextStyle(color: AppTheme.subtext),
                    alignLabelWithHint: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.surface0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingLg),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.send, size: AppSizes.font3xl),
                  label: const Text(AppStrings.contactSend),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    foregroundColor: AppTheme.green,
                    textStyle: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
