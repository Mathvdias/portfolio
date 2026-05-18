import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/constants/app_sizes.dart';
import '../../../../theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../viewmodels/guestbook_viewmodel.dart';
import '../../domain/models/guestbook_message.dart';

class GuestbookContent extends StatefulWidget {
  final GuestbookViewModel viewModel;

  const GuestbookContent({super.key, required this.viewModel});

  @override
  State<GuestbookContent> createState() => _GuestbookContentState();
}

class _GuestbookContentState extends State<GuestbookContent> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _rating = ValueNotifier<int>(5);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    _rating.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    await widget.viewModel.submitMessage(
      _nameCtrl.text,
      _msgCtrl.text,
      _rating.value,
    );

    if (!mounted) return;

    if (widget.viewModel.lastError != null) {
      final error = widget.viewModel.lastError!;
      String errorMsg = error;
      if (error == 'nameMessageEmpty') errorMsg = l10n.nameMessageEmpty;
      if (error == 'waitToPost') errorMsg = l10n.waitToPost;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppTheme.red),
      );
    } else if (widget.viewModel.success) {
      _nameCtrl.clear();
      _msgCtrl.clear();
      _rating.value = 5;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messagePosted),
          backgroundColor: AppTheme.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Container(
          color: AppTheme.background,
          child: Column(
            children: [
              // CTA Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.spacingLg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.blue.withValues(alpha: 0.2),
                      AppTheme.blue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.blue.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave your mark! ✍️',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your feedback makes this portfolio better. Share a message or just say hi!',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: AppTheme.subtext,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Header Form ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSizes.spacingLg),
                color: AppTheme.surface0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.signGuestbook,
                      style: GoogleFonts.spaceMono(
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingMd),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.yourName,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: GoogleFonts.spaceMono(color: AppTheme.text),
                    ),
                    const SizedBox(height: AppSizes.spacingMd),
                    TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.yourMessage,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      style: GoogleFonts.spaceMono(color: AppTheme.text),
                    ),
                    const SizedBox(height: AppSizes.spacingMd),
                    Row(
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: _rating,
                          builder:
                              (_, rating, __) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.rating,
                                    style: GoogleFonts.spaceMono(
                                      color: AppTheme.subtext,
                                    ),
                                  ),
                                  ...List.generate(5, (index) {
                                    return IconButton(
                                      tooltip: l10n.semRateStar(index + 1),
                                      icon: Icon(
                                        index < rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: AppTheme.yellow,
                                      ),
                                      onPressed:
                                          () => _rating.value = index + 1,
                                    );
                                  }),
                                ],
                              ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed:
                              widget.viewModel.isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.blue,
                          ),
                          child:
                              widget.viewModel.isSubmitting
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    l10n.post,
                                    style: GoogleFonts.spaceMono(
                                      color: AppTheme.background,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.surface0),

              // ── Messages List ───────────────────────────────────────
              Expanded(
                child:
                    widget.viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : widget.viewModel.lastError != null &&
                            widget.viewModel.messages.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.spacingLg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.viewModel.lastError!,
                                  style: GoogleFonts.spaceMono(
                                    color: AppTheme.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSizes.spacingMd),
                                TextButton.icon(
                                  onPressed: widget.viewModel.retry,
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: AppTheme.blue,
                                  ),
                                  label: Text(
                                    'Retry Connection',
                                    style: GoogleFonts.spaceMono(
                                      color: AppTheme.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : widget.viewModel.messages.isEmpty
                        ? Center(
                          child: Text(
                            l10n.noMessages,
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.subtext,
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(AppSizes.spacingLg),
                          itemCount: widget.viewModel.messages.length,
                          separatorBuilder:
                              (_, _) =>
                                  const SizedBox(height: AppSizes.spacingLg),
                          itemBuilder: (context, index) {
                            final msg = widget.viewModel.messages[index];
                            return _MessageCard(
                              msg: msg,
                              isAdmin: widget.viewModel.isAdmin,
                              onDelete:
                                  () => widget.viewModel.deleteMessage(msg.id),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  final GuestbookMessage msg;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.msg,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppTheme.surface0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                msg.name,
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const Spacer(),
              Semantics(
                label: l10n.semStarsOutOf5(msg.rating),
                child: Row(
                  children: List.generate(
                    5,
                    (i) => ExcludeSemantics(
                      child: Icon(
                        i < msg.rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: AppTheme.yellow,
                      ),
                    ),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: AppSizes.spacingMd),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete,
                    size: 16,
                    color: AppTheme.red,
                    semanticLabel: l10n.semDeleteMessage,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            msg.message,
            style: GoogleFonts.spaceMono(color: AppTheme.subtext),
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            '${msg.timestamp.day}/${msg.timestamp.month}/${msg.timestamp.year} ${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.overlay),
          ),
        ],
      ),
    );
  }
}
