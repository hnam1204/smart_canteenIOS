import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../models/support_message_model.dart';
import 'support_controller.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  late final SupportController _controller;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller = SupportController()..startWatchingMessages(widget.ticketId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final success = await _controller.sendChatMessage(widget.ticketId, text);
    setState(() => _sending = false);

    if (success) {
      _messageController.clear();
    } else {
      if (mounted) {
        showAppSnackBar(
          context,
          'Không thể gửi tin nhắn. Có thể yêu cầu đã bị đóng.',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final resolvedTicket = _controller.activeTicket;
        
        if (resolvedTicket == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final isClosed = resolvedTicket.status == 'closed';
        final ticketTitle = resolvedTicket.title;
        final ticketStatus = resolvedTicket.status;

        // Reverse messages list so that index 0 is at the bottom of the reverse: true list
        final messages = _controller.messages;
        final reversedMessages = messages.reversed.toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticketTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticketStatus),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusLabel(ticketStatus),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            shape: const Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _controller.loadingMessages
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _controller.hasMessagesError
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Không thể tải tin nhắn',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => _controller.startWatchingMessages(widget.ticketId),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'Chưa có cuộc trò chuyện',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                itemCount: reversedMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = reversedMessages[index];
                                  final isMe = msg.senderRole == 'user';
                                  return _buildMessageBubble(msg, isMe);
                                },
                              ),
              ),
              _buildInputArea(isClosed),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(SupportMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              message.message,
              style: TextStyle(
                fontSize: 13.5,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 9.5,
                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isClosed) {
    if (isClosed) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewPaddingOf(context).bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Yêu cầu đã đóng',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.viewPaddingOf(context).bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary),
            onPressed: () {
              showAppSnackBar(
                context,
                'Tính năng gửi ảnh sẽ khả dụng khi kết nối thiết bị.',
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
              );
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.field,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _sending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }
}
