import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../main_shell_screen.dart';
import '../profile/profile_screen.dart' show ProfileScreen;
import '../widgets/canteen_bottom_nav_bar.dart';
import 'help_center_model.dart';
import 'support_controller.dart';
import 'support_chat_screen.dart';
import 'widgets/support_widgets.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  late final SupportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SupportController()..startWatchingTickets();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replace(Widget screen) {
    AppNavigator.replace<void>(context, builder: (_) => screen);
  }

  void _back() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    _replace(ProfileScreen(cartCount: widget.cartCount));
  }

  void _onNavigationTap(int index) {
    _replace(MainShellScreen(initialIndex: index));
  }

  Future<bool> _submitTicket(ProblemType type, String description) async {
    final success = await _controller.createSupportTicket(
      category: problemTypeLabel(type),
      title: '${problemTypeLabel(type)} cần hỗ trợ',
      message: description,
    );
    if (!mounted) return false;
    showAppSnackBar(
      context,
      success
          ? 'Đã gửi yêu cầu hỗ trợ'
          : 'Không thể gửi yêu cầu. Vui lòng thử lại.',
      icon: success
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
      iconColor: success ? AppColors.success : AppColors.error,
    );
    return success;
  }

  void _openChat(String ticketId) {
    AppNavigator.push<void>(
      context,
      builder: (_) => SupportChatScreen(ticketId: ticketId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _HelpHeader(onBackTap: _back),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    _controller.startWatchingTickets();
                    await Future<void>.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
                    children: [
                      ReportProblemForm(
                        submitting: _controller.submittingTicket,
                        onSubmit: _submitTicket,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Yêu cầu của tôi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_controller.loadingTickets)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (_controller.tickets.isEmpty)
                        const EmptySupportState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _controller.tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _controller.tickets[index];
                            return SupportTicketCard(
                              key: ValueKey(ticket.id),
                              ticket: ticket,
                              onChatTap: () => _openChat(ticket.id),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CanteenBottomNavBar(
          selectedIndex: 4,
          cartCount: widget.cartCount,
          notificationCount: widget.notificationCount,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({required this.onBackTap});
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 9, 9, 9),
      child: SizedBox(
        height: 53,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Quay lại',
                onPressed: onBackTap,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),
            const Text(
              'Trung tâm trợ giúp',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
