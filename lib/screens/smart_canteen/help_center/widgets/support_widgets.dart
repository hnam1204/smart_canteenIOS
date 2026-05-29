import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../help_center_model.dart';

class ContactSupportCard extends StatelessWidget {
  const ContactSupportCard({
    super.key,
    required this.onChatTap,
    required this.onCallTap,
    required this.onEmailTap,
  });

  final VoidCallback onChatTap;
  final VoidCallback onCallTap;
  final VoidCallback onEmailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 29,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hỗ trợ Smart Canteen',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Đang trực tuyến  •  07:00 - 21:30',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '1900 123 456  •  support@smartcanteen.vn',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _SupportButton(
                key: const ValueKey('contact-chat'),
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat ngay',
                filled: true,
                onPressed: onChatTap,
              ),
              const SizedBox(width: 8),
              _SupportButton(
                icon: Icons.call_outlined,
                label: 'Gọi hỗ trợ',
                onPressed: onCallTap,
              ),
              const SizedBox(width: 8),
              _SupportButton(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                onPressed: onEmailTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 42),
                textStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 42),
                textStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}

class ReportProblemForm extends StatefulWidget {
  const ReportProblemForm({
    super.key,
    required this.submitting,
    required this.onSubmit,
  });

  final bool submitting;
  final Future<bool> Function(ProblemType type, String description) onSubmit;

  @override
  State<ReportProblemForm> createState() => _ReportProblemFormState();
}

class _ReportProblemFormState extends State<ReportProblemForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  ProblemType _type = ProblemType.order;
  bool _attached = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || widget.submitting) return;
    final result = await widget.onSubmit(
      _type,
      _descriptionController.text.trim(),
    );
    if (!mounted || !result) return;
    _descriptionController.clear();
    setState(() => _attached = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Báo lỗi nhanh',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<ProblemType>(
              key: const ValueKey('problem-type-field'),
              initialValue: _type,
              isExpanded: true,
              decoration: _inputDecoration(
                label: 'Loại vấn đề',
                icon: Icons.category_outlined,
              ),
              items: ProblemType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(problemTypeLabel(type)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 11),
            TextFormField(
              key: const ValueKey('problem-description-field'),
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 400,
              textInputAction: TextInputAction.newline,
              decoration: _inputDecoration(
                label: 'Mô tả vấn đề',
                icon: Icons.edit_note_rounded,
                hint: 'Cho chúng tôi biết vấn đề bạn gặp phải...',
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 10) {
                  return 'Vui lòng nhập mô tả ít nhất 10 ký tự.';
                }
                return null;
              },
            ),
            const SizedBox(height: 2),
            Material(
              color: _attached ? AppColors.primarySoft : AppColors.field,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                key: const ValueKey('attach-problem-image'),
                borderRadius: BorderRadius.circular(13),
                onTap: () => setState(() => _attached = !_attached),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _attached
                            ? Icons.check_circle_outline_rounded
                            : Icons.add_photo_alternate_outlined,
                        color: _attached
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _attached
                              ? 'Đã thêm ảnh minh họa'
                              : 'Thêm ảnh minh họa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _attached
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: FilledButton(
                key: const ValueKey('submit-support-ticket'),
                onPressed: widget.submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: widget.submitting
                    ? const SizedBox.square(
                        dimension: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Gửi hỗ trợ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.field,
      counterStyle: const TextStyle(fontSize: 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
      ),
    );
  }
}

class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    super.key,
    required this.ticket,
    required this.onDetailsTap,
  });

  final SupportTicketModel ticket;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: _statusColor(ticket.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: _statusColor(ticket.status),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${ticket.id}  •  ${ticket.submittedAt}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                supportStatusLabel(ticket.status),
                style: TextStyle(
                  color: _statusColor(ticket.status),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                key: ValueKey('support-ticket-${ticket.id}'),
                onPressed: onDetailsTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 25),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Xem chi tiết',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(SupportStatus status) => switch (status) {
    SupportStatus.processing => const Color(0xFF2563EB),
    SupportStatus.replied => AppColors.success,
    SupportStatus.closed => AppColors.textSecondary,
  };
}

class SupportTicketDetailSheet extends StatelessWidget {
  const SupportTicketDetailSheet({
    super.key,
    required this.ticket,
    required this.onCloseTicket,
  });

  final SupportTicketModel ticket;
  final VoidCallback onCloseTicket;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        11,
        20,
        MediaQuery.viewPaddingOf(context).bottom + 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            ticket.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${ticket.id}  •  ${supportStatusLabel(ticket.status)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 17),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TicketSection(
                    title: 'Thời gian gửi',
                    content: ticket.submittedAt,
                  ),
                  _TicketSection(
                    title: 'Nội dung',
                    content: ticket.description,
                  ),
                  if (ticket.hasAttachment)
                    Container(
                      height: 55,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: AppColors.field,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Ảnh đính kèm',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  _TicketSection(
                    title: 'Phản hồi từ hỗ trợ',
                    content:
                        ticket.reply ??
                        'Chúng tôi đang kiểm tra yêu cầu của bạn.',
                  ),
                ],
              ),
            ),
          ),
          if (ticket.status != SupportStatus.closed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: OutlinedButton(
                key: const ValueKey('close-support-ticket'),
                onPressed: onCloseTicket,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Đóng ticket'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptySupportState extends StatelessWidget {
  const EmptySupportState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.support_agent_rounded, size: 46, color: AppColors.primary),
          SizedBox(height: 10),
          Text(
            'Chưa có yêu cầu hỗ trợ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Nếu cần trợ giúp hãy liên hệ với chúng tôi',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TicketSection extends StatelessWidget {
  const _TicketSection({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
