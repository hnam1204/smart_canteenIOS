import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/review_repository.dart';
import '../main_shell_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'review_controller.dart';
import 'review_model.dart';
import 'widgets/review_comment_box.dart';
import 'widgets/review_image_picker.dart';
import 'widgets/review_order_card.dart';
import 'widgets/review_success_dialog.dart';
import 'widgets/review_tag_chips.dart';
import 'widgets/service_rating_section.dart';
import 'widgets/star_rating_widget.dart';
import 'widgets/submit_review_button.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    this.orderId,
    this.order = demoReviewOrder,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final String? orderId;
  final ReviewOrderModel order;
  final int cartCount;
  final int notificationCount;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late ReviewController _controller;
  late ReviewOrderModel _currentOrder;
  final TextEditingController _commentController = TextEditingController();
  String? _commentError;
  bool _checkingEligibility = true;
  String? _eligibilityError;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _controller = ReviewController(order: _currentOrder);
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final resolvedOrderId = widget.orderId ?? widget.order.id;
        
        final order = await OrderRepository().getOrder(resolvedOrderId)
            ?? await OrderRepository().getOrderByCode(resolvedOrderId);
        
        if (order == null) {
          setState(() {
            _eligibilityError = 'Đơn hàng không tồn tại.';
            _checkingEligibility = false;
          });
          return;
        }
        if (order.userId != userId) {
          setState(() {
            _eligibilityError = 'Đơn hàng không thuộc tài khoản của bạn.';
            _checkingEligibility = false;
          });
          return;
        }
        if (order.orderStatus != 'delivered' && order.orderStatus != 'completed') {
          setState(() {
            _eligibilityError = 'Bạn chỉ có thể đánh giá sau khi đơn hàng đã hoàn thành.';
            _checkingEligibility = false;
          });
          return;
        }

        final orderItems = order.items.map((item) => ReviewOrderItemModel(
          name: item.name,
          quantity: item.quantity,
          price: item.total ~/ item.quantity,
          imageAsset: item.imageUrl,
        )).toList();
        
        final reviewOrder = ReviewOrderModel(
          id: order.id,
          orderedAt: '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year} - ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
          items: orderItems,
        );

        final oldController = _controller;
        _currentOrder = reviewOrder;
        _controller = ReviewController(order: _currentOrder);
        oldController.dispose();

        final existingReview = await ReviewRepository().getReviewForOrder(order.id);
        if (order.hasReview || existingReview != null) {
          setState(() {
            _alreadyReviewed = true;
            _checkingEligibility = false;
            if (existingReview != null) {
              _controller.setRating(existingReview.rating);
              _commentController.text = existingReview.comment;
              _controller.updateComment(existingReview.comment);
              
              // Clear current tags and copy loaded tags
              _controller.selectedTags.toList().forEach((t) => _controller.toggleTag(t));
              for (final tag in existingReview.tags) {
                _controller.toggleTag(tag);
              }
              existingReview.serviceRatings.forEach((k, v) {
                _controller.setServiceRating(k, v);
              });
            }
          });
          return;
        }
      } catch (e) {
        setState(() {
          _eligibilityError = 'Không thể kiểm tra trạng thái đơn hàng: ${e.toString()}';
          _checkingEligibility = false;
        });
        return;
      }
    }
    setState(() {
      _checkingEligibility = false;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    AppNavigator.replace<void>(
      context,
      builder: (_) => MainShellScreen(initialIndex: index),
    );
  }

  Future<void> _submit() async {
    final error = _controller.validate();
    setState(() => _commentError = error);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    FocusScope.of(context).unfocus();
    final res = await _controller.submit();
    if (!mounted) return;
    if (!res.isSuccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(res.error ?? 'Đã xảy ra lỗi khi gửi đánh giá.')));
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ReviewSuccessDialog(
        onHomeTap: () {
          Navigator.pop(dialogContext);
          _onBottomNavTap(0);
        },
        onHistoryTap: () {
          Navigator.pop(dialogContext);
          _openHistory();
        },
      ),
    );
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewHistorySheet(
        reviews: _controller.history,
        onEdit: (review) {
          Navigator.pop(context);
          _controller.editReview(review);
          _commentController.text = review.comment;
          setState(() => _commentError = null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingEligibility) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_eligibilityError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  _eligibilityError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ReviewHeader(
                  onBackTap: () => Navigator.maybePop(context),
                  onHistoryTap: _openHistory,
                ),
                Expanded(
                  child: ListView(
                    key: const ValueKey('review-content-list'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 26),
                    children: [
                      ReviewOrderCard(order: _currentOrder),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Bạn hài lòng với đơn hàng này chứ?',
                        centered: true,
                        child: Column(
                          children: [
                            StarRatingWidget(
                              rating: _controller.rating,
                              onChanged: _alreadyReviewed ? null : (rating) {
                                _controller.setRating(rating);
                                if (_commentError != null) {
                                  setState(() => _commentError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 210),
                              child: Text(
                                _controller.ratingLabel,
                                key: ValueKey(_controller.ratingLabel),
                                style: TextStyle(
                                  color: _controller.rating > 0
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Bạn thích điều gì?',
                        subtitle: 'Chọn nhiều mục nếu phù hợp',
                        child: ReviewTagChips(
                          tags: demoReviewTags,
                          selectedTags: _controller.selectedTags,
                          onSelected: _alreadyReviewed ? null : _controller.toggleTag,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Chia sẻ trải nghiệm',
                        subtitle: 'Bắt buộc nếu bạn đánh giá dưới 3 sao',
                        child: ReviewCommentBox(
                          controller: _commentController,
                          errorText: _commentError,
                          enabled: !_alreadyReviewed,
                          onChanged: _alreadyReviewed ? (text) {} : (text) {
                            _controller.updateComment(text);
                            if (_commentError != null &&
                                text.trim().isNotEmpty) {
                              setState(() => _commentError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Ảnh đánh giá',
                        subtitle: 'Thêm tối đa 3 ảnh',
                        child: ReviewImagePicker(
                          images: _controller.images,
                          onAdd: _alreadyReviewed ? () {} : _controller.addImage,
                          onRemove: _alreadyReviewed ? (id) {} : _controller.removeImage,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Đánh giá chi tiết',
                        child: ServiceRatingSection(
                          services: demoServiceRatings,
                          ratings: _controller.serviceRatings,
                          onChanged: _alreadyReviewed ? null : _controller.setServiceRating,
                        ),
                      ),
                      const SizedBox(height: 17),
                      if (_alreadyReviewed) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.success),
                                SizedBox(width: 8),
                                Text(
                                  'Bạn đã đánh giá đơn hàng này rồi.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        SubmitReviewButton(
                          enabled: _controller.canSubmit,
                          loading: _controller.submitting,
                          onPressed: _submit,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CanteenBottomNavBar(
            selectedIndex: -1,
            cartCount: widget.cartCount,
            notificationCount: widget.notificationCount,
            onTap: _onBottomNavTap,
          ),
        );
      },
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.onBackTap, required this.onHistoryTap});

  final VoidCallback onBackTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
      child: SizedBox(
        height: 54,
        child: Stack(
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
              'Đánh giá',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: const ValueKey('open-review-history'),
                tooltip: 'Lịch sử đánh giá',
                onPressed: onHistoryTap,
                icon: const Icon(Icons.history_rounded),
                color: AppColors.textPrimary,
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.centered = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _ReviewHistorySheet extends StatelessWidget {
  const _ReviewHistorySheet({required this.reviews, required this.onEdit});

  final List<ReviewModel> reviews;
  final ValueChanged<ReviewModel> onEdit;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 11),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  Text(
                    'Lịch sử đánh giá',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: const ValueKey('review-history-list'),
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 11),
                itemBuilder: (context, index) => _HistoryCard(
                  review: reviews[index],
                  onEdit: reviews[index].canEdit
                      ? () => onEdit(reviews[index])
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.review, this.onEdit});

  final ReviewModel review;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Đã gửi',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var index = 0; index < 5; index++)
                Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 18,
                  color: index < review.rating
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              const SizedBox(width: 8),
              Text(
                review.createdAt,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              review.comment,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ],
          if (onEdit != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              key: ValueKey('edit-review-${review.orderId}'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Chỉnh sửa đánh giá'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
