import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../all_orders/all_orders_screen.dart';
import '../main_shell_screen.dart';
import '../profile/profile_screen.dart' show ProfileScreen;
import '../widgets/canteen_bottom_nav_bar.dart';
import 'help_center_controller.dart';
import 'help_center_model.dart';
import 'widgets/faq_widgets.dart';
import 'widgets/help_banner.dart';
import 'widgets/quick_support_grid.dart';
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
  late final HelpCenterController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _contentScrollController = ScrollController();
  final GlobalKey _contactKey = GlobalKey();
  final GlobalKey _reportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = HelpCenterController()..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contentScrollController.dispose();
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

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
  }

  void _openChat() {
    AppNavigator.push<void>(context, builder: (_) => const ChatSupportScreen());
  }

  void _showPhoneAction() {
    showAppSnackBar(
      context,
      'Hotline hỗ trợ: 1900 123 456',
      icon: Icons.call_outlined,
      iconColor: AppColors.success,
    );
  }

  void _showEmailAction() {
    showAppSnackBar(
      context,
      'Email hỗ trợ: support@smartcanteen.vn',
      icon: Icons.mail_outline_rounded,
      iconColor: const Color(0xFF2563EB),
    );
  }

  void _handleQuickAction(QuickSupportAction action) {
    switch (action) {
      case QuickSupportAction.contact:
        _scrollToSection(_contactKey, fallbackOffset: 920);
        return;
      case QuickSupportAction.liveChat:
        _openChat();
        return;
      case QuickSupportAction.hotline:
        _showPhoneAction();
        return;
      case QuickSupportAction.reportIssue:
        _scrollToSection(_reportKey, fallbackOffset: 1140);
        return;
      case QuickSupportAction.trackOrder:
        AppNavigator.push<void>(
          context,
          builder: (_) => AllOrdersScreen(cartCount: widget.cartCount),
        );
        return;
      case QuickSupportAction.refundPolicy:
        AppNavigator.push<void>(
          context,
          builder: (_) => const RefundPolicyScreen(),
        );
        return;
    }
  }

  Future<void> _scrollToSection(
    GlobalKey key, {
    required double fallbackOffset,
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final targetContext = key.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (!_contentScrollController.hasClients) {
        return;
      }
      final position = _contentScrollController.position;
      await _contentScrollController.animateTo(
        fallbackOffset.clamp(0, position.maxScrollExtent),
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) {
        return;
      }
    }
  }

  Future<bool> _submitTicket(ProblemType type, String description) async {
    final success = await _controller.submitTicket(type, description);
    if (!mounted) return false;
    showAppSnackBar(
      context,
      success
          ? 'Yêu cầu hỗ trợ đã được gửi thành công.'
          : 'Không thể gửi yêu cầu. Vui lòng thử lại.',
      icon: success
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
      iconColor: success ? AppColors.success : AppColors.error,
    );
    return success;
  }

  void _openTicket(SupportTicketModel ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SupportTicketDetailSheet(
        ticket: ticket,
        onCloseTicket: () {
          _controller.closeTicket(ticket.id);
          Navigator.pop(sheetContext);
          showAppSnackBar(context, 'Ticket ${ticket.id} đã được đóng.');
        },
      ),
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
              _HelpHeader(onBackTap: _back, onChatTap: _openChat),
              _HelpSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _controller.updateSearch,
                onClear: _clearSearch,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _controller.loading
                      ? const _HelpLoading(key: ValueKey('help-loading'))
                      : _controller.hasError
                      ? _HelpError(
                          key: const ValueKey('help-error'),
                          onRetry: _controller.retry,
                        )
                      : _HelpContent(
                          key: const ValueKey('help-content'),
                          controller: _controller,
                          scrollController: _contentScrollController,
                          contactKey: _contactKey,
                          reportKey: _reportKey,
                          onRefresh: _controller.refresh,
                          onQuickActionTap: _handleQuickAction,
                          onChatTap: _openChat,
                          onCallTap: _showPhoneAction,
                          onEmailTap: _showEmailAction,
                          onSubmitTicket: _submitTicket,
                          onTicketTap: _openTicket,
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
  const _HelpHeader({required this.onBackTap, required this.onChatTap});

  final VoidCallback onBackTap;
  final VoidCallback onChatTap;

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
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: const ValueKey('header-chat-support'),
                tooltip: 'Chat hỗ trợ',
                onPressed: onChatTap,
                icon: const Icon(Icons.support_agent_rounded, size: 25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSearchBar extends StatefulWidget {
  const _HelpSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_HelpSearchBar> createState() => _HelpSearchBarState();
}

class _HelpSearchBarState extends State<_HelpSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_update);
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_update);
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.focusNode.hasFocus
              ? AppColors.primary
              : AppColors.divider,
          width: widget.focusNode.hasFocus ? 1.4 : 1,
        ),
        boxShadow: widget.focusNode.hasFocus ? AppColors.cardShadow : null,
      ),
      child: TextField(
        key: const ValueKey('help-search-field'),
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm câu hỏi, chủ đề hỗ trợ',
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  key: const ValueKey('clear-help-search'),
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _HelpContent extends StatelessWidget {
  const _HelpContent({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.contactKey,
    required this.reportKey,
    required this.onRefresh,
    required this.onQuickActionTap,
    required this.onChatTap,
    required this.onCallTap,
    required this.onEmailTap,
    required this.onSubmitTicket,
    required this.onTicketTap,
  });

  final HelpCenterController controller;
  final ScrollController scrollController;
  final GlobalKey contactKey;
  final GlobalKey reportKey;
  final Future<void> Function() onRefresh;
  final ValueChanged<QuickSupportAction> onQuickActionTap;
  final VoidCallback onChatTap;
  final VoidCallback onCallTap;
  final VoidCallback onEmailTap;
  final Future<bool> Function(ProblemType type, String description)
  onSubmitTicket;
  final ValueChanged<SupportTicketModel> onTicketTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView(
            key: const ValueKey('help-content-list'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
            children: [
              if (controller.refreshing)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                ),
              HelpBanner(onChatTap: onChatTap),
              const SizedBox(height: 21),
              const _SectionTitle(title: 'Hỗ trợ nhanh'),
              const SizedBox(height: 12),
              QuickSupportGrid(
                actions: quickSupportActions,
                onTap: onQuickActionTap,
              ),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Câu hỏi thường gặp'),
              const SizedBox(height: 12),
              FAQCategoryTabs(
                selected: controller.category,
                countFor: controller.countFor,
                onSelected: controller.setCategory,
              ),
              const SizedBox(height: 12),
              if (controller.visibleFaqs.isEmpty)
                const _EmptyFAQ()
              else
                FAQAccordionList(items: controller.visibleFaqs),
              const SizedBox(height: 17),
              const _SectionTitle(title: 'Liên hệ hỗ trợ'),
              const SizedBox(height: 11),
              KeyedSubtree(
                key: contactKey,
                child: ContactSupportCard(
                  onChatTap: onChatTap,
                  onCallTap: onCallTap,
                  onEmailTap: onEmailTap,
                ),
              ),
              const SizedBox(height: 19),
              KeyedSubtree(
                key: reportKey,
                child: ReportProblemForm(
                  submitting: controller.submitting,
                  onSubmit: onSubmitTicket,
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Yêu cầu đã gửi'),
              const SizedBox(height: 11),
              if (controller.tickets.isEmpty)
                const EmptySupportState()
              else
                for (final ticket in controller.tickets)
                  SupportTicketCard(
                    key: ValueKey(ticket.id),
                    ticket: ticket,
                    onDetailsTap: () => onTicketTap(ticket),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyFAQ extends StatelessWidget {
  const _EmptyFAQ();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.textTertiary,
            size: 39,
          ),
          SizedBox(height: 9),
          Text(
            'Không tìm thấy câu hỏi phù hợp',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HelpLoading extends StatelessWidget {
  const _HelpLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
      children: const [
        _Skeleton(height: 104),
        SizedBox(height: 18),
        _Skeleton(height: 246),
        SizedBox(height: 18),
        _Skeleton(height: 210),
        SizedBox(height: 18),
        _Skeleton(height: 168),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.divider),
      ),
    );
  }
}

class _HelpError extends StatelessWidget {
  const _HelpError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.textTertiary,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text('Không thể tải trung tâm trợ giúp.'),
          const SizedBox(height: 13),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class ChatSupportScreen extends StatelessWidget {
  const ChatSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chat hỗ trợ'),
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 33,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Hỗ trợ viên đang trực tuyến',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Kết nối chat realtime sẽ được tích hợp cùng backend hỗ trợ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Chính sách hoàn tiền'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: const [
            _PolicyCard(
              title: 'Thanh toán lỗi',
              content:
                  'Giao dịch bị trừ tiền nhưng đơn không tạo thành công sẽ được đối soát và hoàn tiền trong 1-3 ngày làm việc.',
            ),
            SizedBox(height: 12),
            _PolicyCard(
              title: 'Thiếu món hoặc sai món',
              content:
                  'Liên hệ hỗ trợ trong vòng 24 giờ kèm hình ảnh để nhận voucher bồi hoàn hoặc hoàn tiền phù hợp.',
            ),
            SizedBox(height: 12),
            _PolicyCard(
              title: 'Hủy đơn',
              content:
                  'Đơn hủy trước khi nhà bếp xác nhận sẽ được hoàn toàn bộ giá trị đã thanh toán.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
