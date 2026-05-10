import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

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
      path: 'mattmvc56@gmail.com',
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
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300, // Give it a fixed height inside the window
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Message',
                style: GoogleFonts.spaceMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectCtrl,
                style: GoogleFonts.spaceMono(
                  color: AppTheme.text,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: AppTheme.subtext),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.surface0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.text,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Message',
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send'),
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
