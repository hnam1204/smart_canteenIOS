import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/colors.dart';
import '../../../../models/support_ticket_model.dart';
import '../help_center_model.dart' hide SupportTicketModel;

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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tạo yêu cầu hỗ trợ',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
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
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
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
    required this.onChatTap,
  });

  final SupportTicketModel ticket;
  final VoidCallback onChatTap;

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Đơn hàng':
      case 'order':
        return Icons.receipt_long_outlined;
      case 'Thanh toán':
      case 'payment':
        return Icons.payment_outlined;
      case 'App lỗi':
      case 'application':
        return Icons.bug_report_outlined;
      case 'Tài khoản':
      case 'account':
        return Icons.account_circle_outlined;
      default:
        return Icons.support_agent_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF2563EB);
      case 'replied':
        return const Color(0xFF16A34A);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Đang xử lý';
      case 'replied':
        return 'Đã phản hồi';
      case 'closed':
        return 'Đã đóng';
      default:
        return status;
    }
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.status);
    final isFirebaseInitialized = Firebase.apps.isNotEmpty;

    return GestureDetector(
      onTap: onChatTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(ticket.category),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(ticket.updatedAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ticket.lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusLabel(ticket.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (ticket.unreadByUser) ...[
                            if (isFirebaseInitialized)
                              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('support_tickets')
                                    .doc(ticket.id)
                                    .collection('messages')
                                    .where('senderRole', isEqualTo: 'admin')
                                    .where('isRead', isEqualTo: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${snapshot.data!.docs.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                          TextButton(
                            onPressed: onChatTap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: AppColors.primarySoft,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              ticket.status == 'closed' ? 'Xem chi tiết' : 'Chat ngay',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptySupportState extends StatelessWidget {
  const EmptySupportState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.support_agent_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Chưa có yêu cầu hỗ trợ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Gửi yêu cầu hỗ trợ khi gặp sự cố, chúng tôi sẽ phản hồi sớm nhất.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
