import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../order_history/order_history_screen.dart';
import '../main_shell_screen.dart' show MainShellController, MainShellScreen;
import 'order_model.dart';
import 'qr_pickup_controller.dart';
import 'widgets/note_card.dart';
import 'widgets/order_info_card.dart';
import 'widgets/pickup_location_card.dart';
import 'widgets/qr_code_card.dart';
import 'widgets/success_banner.dart';

class QRPickupScreen extends StatefulWidget {
  const QRPickupScreen({super.key, required this.orderId, this.previewOrder});

  final String orderId;
  final OrderModel? previewOrder;

  @override
  State<QRPickupScreen> createState() => _QRPickupScreenState();
}

class _QRPickupScreenState extends State<QRPickupScreen> {
  late final QRPickupController _controller;

  @override
  void initState() {
    super.initState();
    debugPrint('QRPickup received orderId: ${widget.orderId}');
    _controller = QRPickupController(
      orderId: widget.orderId,
      previewOrder: widget.previewOrder,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyOrderId() async {
    final order = _controller.order;
    if (order == null) return;
    await Clipboard.setData(ClipboardData(text: order.id));
    if (!mounted) return;
    showAppSnackBar(context, 'Đã sao chép mã đơn hàng ${order.id}.');
  }

  Future<void> _refreshQr() async {
    await _controller.refreshQrCode();
    if (!mounted) return;
    showAppSnackBar(context, 'Đã tải lại trạng thái mã nhận món.');
  }

  void _openGuide() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QrGuideSheet(),
    );
  }

  void _openMap() {
    showAppSnackBar(
      context,
      'Quầy A nằm tại khu nhận món tầng trệt.',
      icon: Icons.location_on_rounded,
      iconColor: AppColors.primary,
    );
  }

  void _goToOrderHistory() {
    if (!mounted) return;
    AppNavigator.push<void>(
      context,
      builder: (_) => const OrderHistoryScreen(),
    );
  }

  void _goToHome() {
    if (!mounted) return;
    final controller = MainShellController.maybeOf(context);
    if (controller != null) {
      // Inside shell: just switch tab
      controller.jumpToTab(0);
    } else {
      // Outside shell (standalone navigation): replace entire stack
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => const MainShellScreen(initialIndex: 0),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _QrHeader(
                  onBackTap: () => Navigator.maybePop(context),
                  onGuideTap: _openGuide,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _controller.loading && _controller.retryCount == 0
                        ? const _QrLoading(key: ValueKey('qr-loading'))
                        : _controller.isRetrying
                        ? _QrRetrying(
                            retryCount: _controller.retryCount,
                            key: const ValueKey('qr-retrying'),
                          )
                        : _controller.order == null
                        ? _QrErrorState(
                            message:
                                _controller.error ??
                                'Không thể hiển thị mã QR.',
                            onRetry: _controller.load,
                            onBackToOrders: () => Navigator.maybePop(context),
                            key: const ValueKey('qr-error'),
                          )
                        : _QrContent(
                            key: const ValueKey('qr-content'),
                            order: _controller.order!,
                            qrData: _controller.qrData,
                            onCopyTap: _copyOrderId,
                            onRefreshTap: _refreshQr,
                            onMapTap: _openMap,
                            onViewHistoryTap: _goToOrderHistory,
                            onGoHomeTap: _goToHome,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QrHeader extends StatelessWidget {
  const _QrHeader({required this.onBackTap, required this.onGuideTap});

  final VoidCallback onBackTap;
  final VoidCallback onGuideTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 9, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 370;
          return SizedBox(
            height: 55,
            child: compact
                ? Row(
                    children: [
                      IconButton(
                        tooltip: 'Quay lại',
                        onPressed: onBackTap,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textPrimary,
                        iconSize: 20,
                      ),
                      const Expanded(
                        child: Text(
                          'Mã QR nhận món',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hướng dẫn',
                        onPressed: onGuideTap,
                        color: AppColors.primary,
                        icon: const Icon(Icons.help_outline_rounded, size: 22),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Quay lại',
                          onPressed: onBackTap,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: AppColors.textPrimary,
                          iconSize: 21,
                        ),
                      ),
                      const Text(
                        'Mã QR nhận món',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onGuideTap,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            size: 20,
                          ),
                          label: const Text('Hướng dẫn'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _QrContent extends StatelessWidget {
  const _QrContent({
    super.key,
    required this.order,
    required this.qrData,
    required this.onCopyTap,
    required this.onRefreshTap,
    required this.onMapTap,
    required this.onViewHistoryTap,
    required this.onGoHomeTap,
  });

  final OrderModel order;
  final String qrData;
  final VoidCallback onCopyTap;
  final VoidCallback onRefreshTap;
  final VoidCallback onMapTap;
  final VoidCallback onViewHistoryTap;
  final VoidCallback onGoHomeTap;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 370
        ? 14.0
        : 18.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 670),
        child: ListView(
          key: const ValueKey('qr-content-list'),
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            5,
            horizontalPadding,
            24,
          ),
          children: [
            SuccessBanner(
              title: _bannerTitle(order),
              message: _bannerMessage(order),
              icon: _bannerIcon(order),
              foreground: _bannerForeground(order),
              background: _bannerBackground(order),
            ),
            const SizedBox(height: 15),
            if (order.isCancelled)
              const _CancelledOrderCard()
            else ...[
              QRCodeCard(
                order: order,
                qrData: qrData,
                secondsRemaining: 0,
                onCopyTap: onCopyTap,
                onRefreshTap: onRefreshTap,
              ),
              const SizedBox(height: 14),
            ],
            PickupLocationCard(order: order, onMapTap: onMapTap),
            const SizedBox(height: 14),
            OrderInfoCard(order: order),
            const SizedBox(height: 14),
            const NoteCard(),
            const SizedBox(height: 16),
            _QrNavigationButtons(
              onViewHistoryTap: onViewHistoryTap,
              onGoHomeTap: onGoHomeTap,
            ),
          ],
        ),
      ),
    );
  }

  String _bannerTitle(OrderModel order) {
    if (order.isCancelled) return 'Đơn hàng đã bị hủy';
    return switch (order.orderStatus) {
      'pending' => 'Đơn hàng đang chờ xác nhận',
      'preparing' => 'Đơn hàng đang chuẩn bị',
      'ready' => 'Đơn hàng sẵn sàng nhận món',
      'completed' => 'Đơn hàng đã hoàn thành',
      _ => 'Đơn hàng đang được xử lý',
    };
  }

  String _bannerMessage(OrderModel order) {
    if (order.isCancelled) return 'Mã QR đã bị vô hiệu hóa cho đơn hàng này.';
    if (order.paymentStatus == 'pending' && order.paymentMethod == 'bankQr') {
      return 'Chờ xác nhận chuyển khoản từ hệ thống. Bạn vẫn có thể theo dõi trạng thái đơn.';
    }
    if (order.paymentStatus == 'unpaid' && order.paymentMethod == 'cash') {
      return 'Vui lòng thanh toán tại quầy khi nhận món.';
    }
    return 'Vui lòng đến quầy và đưa mã QR cho nhân viên để nhận món.';
  }

  IconData _bannerIcon(OrderModel order) {
    if (order.isCancelled) return Icons.cancel_rounded;
    if (order.orderStatus == 'pending') return Icons.hourglass_top_rounded;
    if (order.orderStatus == 'preparing') return Icons.restaurant_rounded;
    return Icons.check_rounded;
  }

  Color _bannerForeground(OrderModel order) {
    if (order.isCancelled) return AppColors.error;
    if (order.orderStatus == 'pending') return AppColors.primary;
    if (order.orderStatus == 'preparing') return const Color(0xFF1976D2);
    return AppColors.success;
  }

  Color _bannerBackground(OrderModel order) {
    if (order.isCancelled) return const Color(0xFFFFEEEE);
    if (order.orderStatus == 'pending') return AppColors.primarySoft;
    if (order.orderStatus == 'preparing') return const Color(0xFFEAF4FF);
    return const Color(0xFFEFF9F2);
  }
}

/// Navigation action buttons shown at the bottom of the QR pickup screen.
class _QrNavigationButtons extends StatelessWidget {
  const _QrNavigationButtons({
    required this.onViewHistoryTap,
    required this.onGoHomeTap,
  });

  final VoidCallback onViewHistoryTap;
  final VoidCallback onGoHomeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary: View order history
        FilledButton.icon(
          key: const ValueKey('qr-view-history-btn'),
          onPressed: onViewHistoryTap,
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: const Text(
            'Xem lịch sử đơn hàng',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Secondary: Go home
        OutlinedButton.icon(
          key: const ValueKey('qr-go-home-btn'),
          onPressed: onGoHomeTap,
          icon: const Icon(Icons.home_outlined, size: 18),
          label: const Text(
            'Về trang chủ',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.divider, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrLoading extends StatelessWidget {
  const _QrLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 22),
      children: const [
        _LoadingBlock(height: 83),
        SizedBox(height: 15),
        _LoadingBlock(height: 438),
        SizedBox(height: 14),
        _LoadingBlock(height: 72),
        SizedBox(height: 14),
        _LoadingBlock(height: 290),
      ],
    );
  }
}

class _QrRetrying extends StatelessWidget {
  const _QrRetrying({required this.retryCount, super.key});

  final int retryCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 54,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Đang đồng bộ đơn hàng...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử lần $retryCount/5',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrErrorState extends StatelessWidget {
  const _QrErrorState({
    required this.message,
    required this.onRetry,
    required this.onBackToOrders,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBackToOrders;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: onBackToOrders,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Quay lại đơn hàng'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tải lại'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledOrderCard extends StatelessWidget {
  const _CancelledOrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.block_rounded, color: AppColors.error),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đơn hàng đã bị hủy',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(17),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          height: 15,
          width: 150,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _QrGuideSheet extends StatelessWidget {
  const _QrGuideSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        21,
        12,
        21,
        MediaQuery.paddingOf(context).bottom + 22,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _SheetHandle()),
          SizedBox(height: 19),
          Text(
            'Hướng dẫn nhận món',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          _GuideStep(
            number: '1',
            text: 'Đến đúng quầy nhận món hiển thị trên màn hình.',
          ),
          _GuideStep(
            number: '2',
            text: 'Mở mã QR còn hiệu lực và đưa cho nhân viên quét.',
          ),
          _GuideStep(number: '3', text: 'Kiểm tra món trước khi rời quầy.'),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
