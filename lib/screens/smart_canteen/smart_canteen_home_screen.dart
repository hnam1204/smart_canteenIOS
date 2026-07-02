import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../repositories/voucher_repository.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../models/firestore_models.dart' as store;
import '../../repositories/cart_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/food_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/user_repository.dart';
import 'cart_screen.dart' as cart;
import 'food_detail_screen.dart' as detail;
import 'menu_screen.dart' as menu;
import 'notifications/notification_screen.dart';
import 'order_history/order_history_screen.dart';
import 'profile/profile_screen.dart';
import 'review/review_screen.dart';
import 'review/review_model.dart' as review;
import 'widgets/canteen_bottom_nav_bar.dart';
import 'widgets/category_filter_bar.dart';

const _orange = AppColors.primary;
const _textPrimary = AppColors.textPrimary;
const _textSecondary = AppColors.textSecondary;
const _surface = AppColors.surface;
const _background = AppColors.background;
const _shadow = Color(0x0C18253D);

class SmartCanteenHomeScreen extends StatefulWidget {
  const SmartCanteenHomeScreen({
    super.key,
    this.embedded = false,
    this.onTabSelected,
  });

  final bool embedded;
  final ValueChanged<int>? onTabSelected;

  @override
  State<SmartCanteenHomeScreen> createState() => _SmartCanteenHomeScreenState();
}

class _SmartCanteenHomeScreenState extends State<SmartCanteenHomeScreen> {
  final ValueNotifier<String> _selectedCategoryId = ValueNotifier(
    CategoryFilterItem.allId,
  );
  int _selectedTab = 0;
  int _cartCount = 2;
  int _notificationCount = 3;
  String _fullName = 'Minh';
  List<CategoryFilterItem> _categories = _CategorySection.demoCategories;
  List<_FoodData> _foods = _PopularFoodSection.demoFoods;
  review.ReviewOrderModel? _reviewOrder;
  StreamSubscription<List<store.CategoryModel>>? _categorySubscription;
  StreamSubscription<List<store.FoodModel>>? _foodSubscription;
  StreamSubscription<store.UserModel?>? _userSubscription;
  StreamSubscription<store.CartModel?>? _cartSubscription;
  StreamSubscription<List<store.NotificationModel>>? _notificationSubscription;
  StreamSubscription<List<store.OrderModel>>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user == null) return;
    _cartCount = 0;
    _notificationCount = 0;
    _fullName = 'Bạn';
    _categories = const [CategoryFilterItem.all];
    _foods = const [];
    _categorySubscription = CategoryRepository().watchCategories().listen((
      items,
    ) {
      if (!mounted) return;
      setState(() {
        _categories = categoryFilterItems(items);
        if (!_categories.any((item) => item.id == _selectedCategoryId.value)) {
          _selectedCategoryId.value = CategoryFilterItem.allId;
        }
      });
    });
    _foodSubscription = FoodRepository().watchFoods().listen((items) {
      if (!mounted) return;
      setState(() {
        _foods = items
            .map(
              (item) => _FoodData(
                item.name,
                _formatMoney(item.price),
                item.imageUrl,
                categoryId: item.categoryId,
                categoryName: item.categoryName,
                foodId: item.id,
                description: item.description,
                rating: item.rating,
              ),
            )
            .toList(growable: false);
      });
    });
    _userSubscription = UserRepository().watchUser(user.uid).listen((profile) {
      if (!mounted || profile == null) return;
      setState(() => _fullName = profile.fullName.split(' ').last);
    });
    _cartSubscription = CartRepository().watchCart(user.uid).listen((cart) {
      if (!mounted) return;
      setState(() {
        _cartCount =
            cart?.items.fold<int>(0, (total, item) => total + item.quantity) ??
            0;
      });
    });
    _notificationSubscription = NotificationRepository()
        .watchNotifications(user.uid)
        .listen((items) {
          if (!mounted) return;
          setState(() {
            _notificationCount = items.where((item) => !item.isRead).length;
          });
        });
    _orderSubscription = OrderRepository().watchOrders(user.uid).listen((
      orders,
    ) {
      if (!mounted) return;
      final candidate = orders.cast<store.OrderModel?>().firstWhere(
        (order) =>
            order != null &&
            (order.orderStatus == 'completed' ||
                order.orderStatus == 'delivered'),
        orElse: () => orders.isEmpty ? null : orders.first,
      );
      if (candidate == null) return;
      setState(() {
        _reviewOrder = review.ReviewOrderModel(
          id: candidate.orderCode.isEmpty ? candidate.id : candidate.orderCode,
          orderedAt:
              '${candidate.createdAt.day.toString().padLeft(2, '0')}/${candidate.createdAt.month.toString().padLeft(2, '0')}/${candidate.createdAt.year}',
          items: candidate.items
              .map(
                (item) => review.ReviewOrderItemModel(
                  name: item.name,
                  quantity: item.quantity,
                  price: item.total ~/ item.quantity,
                  imageAsset: item.imageUrl,
                ),
              )
              .toList(growable: false),
        );
      });
    });
  }

  @override
  void dispose() {
    unawaited(_categorySubscription?.cancel());
    unawaited(_foodSubscription?.cancel());
    unawaited(_userSubscription?.cancel());
    unawaited(_cartSubscription?.cancel());
    unawaited(_notificationSubscription?.cancel());
    unawaited(_orderSubscription?.cancel());
    _selectedCategoryId.dispose();
    super.dispose();
  }

  void _push(Widget screen) {
    AppNavigator.push<void>(context, builder: (_) => screen);
  }

  void _openTab(int index, Widget screen) {
    final onTabSelected = widget.onTabSelected;
    if (onTabSelected != null) {
      onTabSelected(index);
      return;
    }
    _push(screen);
  }

  void _openFoodDetail(_FoodData food) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: detail.FoodDetailScreen(
            foodId: food.foodId,
            name: food.name,
            description: food.description,
            imageAsset: food.image,
            basePrice: _parsePrice(food.price),
            categoryId: food.categoryId,
            categoryName: food.categoryName,
            rating: food.rating,
          ),
        ),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDiscountBanner() {
    if (Firebase.apps.isEmpty) {
      return _DiscountCard(
        voucher: store.VoucherModel(
          id: 'demo',
          title: 'Ưu đãi đặc biệt dành cho bạn!',
          code: 'DEMO20',
          description: 'Giảm 20% cho đơn hàng từ 40.000đ',
          discountType: 'percent',
          discountValue: 20,
          minOrderAmount: 40000,
          maxDiscount: 10000,
          usageLimit: 1,
          usedCount: 0,
          claimLimit: 1,
          claimedCount: 0,
          userLimit: 1,
          exchangePoints: 0,
          isExchangeable: false,
          isClaimable: true,
          isActive: true,
          expiredAt: DateTime.now().add(const Duration(days: 30)),
        ),
        onClaimTap: () {},
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    if (user == null) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('vouchers')
            .where('isActive', isEqualTo: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
          final activeVouchers = snapshot.data!.docs
              .map((doc) => store.VoucherModel.fromFirestore(doc))
              .where((v) => v.isClaimable && v.claimedCount < v.claimLimit)
              .toList();
          if (activeVouchers.isEmpty) return const SizedBox.shrink();
          final targetVoucher = activeVouchers.first;
          return Column(
            children: [
              _DiscountCard(
                voucher: targetVoucher,
                onClaimTap: () {
                  showAppSnackBar(
                    context,
                    'Vui lòng đăng nhập để nhận voucher.',
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.warning,
                  );
                },
              ),
              const SizedBox(height: 27),
            ],
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('vouchers')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .snapshots(),
      builder: (context, vouchersSnapshot) {
        if (!vouchersSnapshot.hasData || vouchersSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final activeVouchers = vouchersSnapshot.data!.docs
            .map((doc) => store.VoucherModel.fromFirestore(doc))
            .toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('user_vouchers')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, userVouchersSnapshot) {
            if (!userVouchersSnapshot.hasData) return const SizedBox.shrink();
            final claimedVoucherIds = userVouchersSnapshot.data!.docs
                .map((doc) {
                  final data = doc.data();
                  final rawId = data['voucherId'];
                  if (rawId == null) {
                    debugPrint(
                      'Invalid user_voucher missing voucherId: ${doc.id}',
                    );
                    return '';
                  }
                  return rawId.toString().trim();
                })
                .where((id) => id.isNotEmpty)
                .toSet();

            final claimableVouchers = activeVouchers
                .where((v) => !claimedVoucherIds.contains(v.id) && v.isClaimable && v.claimedCount < v.claimLimit)
                .toList();

            if (claimableVouchers.isEmpty) return const SizedBox.shrink();

            final targetVoucher = claimableVouchers.first;

            return Column(
              children: [
                _DiscountCard(
                  voucher: targetVoucher,
                  onClaimTap: () async {
                                        final result = await VoucherRepository().claimVoucher(user.uid, targetVoucher.id);
                    if (!context.mounted) return;
                    if (result.isSuccess) {
                      showAppSnackBar(
                        context,
                        'Đã lưu mã ưu đãi',
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.success,
                      );
                    } else {
                      showAppSnackBar(
                        context,
                        result.error ?? 'Đã xảy ra lỗi khi nhận voucher.',
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.error,
                      );
                    }
                  },
                ),
                const SizedBox(height: 27),
              ],
            );
          },
        );
      },
    );
  }

  void _openReview() {
    final order = _reviewOrder;
    if (Firebase.apps.isEmpty) {
      _push(const ReviewScreen());
      return;
    }
    if (order == null) {
      showAppSnackBar(context, 'Bạn chưa có đơn hàng để đánh giá.');
      return;
    }
    _push(
      ReviewScreen(
        order: order,
        cartCount: _cartCount,
        notificationCount: _notificationCount,
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedTab = index);
    switch (index) {
      case 1:
        _openTab(1, const menu.MenuScreen());
        return;
      case 2:
        _openTab(2, const cart.CartScreen());
        return;
      case 3:
        _openTab(3, const NotificationScreen());
        return;
      case 4:
        _openTab(4, ProfileScreen(cartCount: _cartCount));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 370 ? 16.0 : 20.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    userName: _fullName,
                    notificationCount: _notificationCount,
                    onNotificationTap: () =>
                        _openTab(3, const NotificationScreen()),
                    onQrTap: () => showAppSnackBar(
                      context,
                      'Vui lòng mở đơn hàng hợp lệ để xem mã QR nhận món.',
                      icon: Icons.qr_code_rounded,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PromoBanner(
                    onExploreTap: () => _openTab(1, const menu.MenuScreen()),
                  ),
                  const SizedBox(height: 18),
                  _QuickActions(
                    cartCount: _cartCount,
                    onOrderTap: () => _openTab(1, const menu.MenuScreen()),
                    onCartTap: () => _openTab(2, const cart.CartScreen()),
                    onHistoryTap: () =>
                        _push(OrderHistoryScreen(cartCount: _cartCount)),
                    onReviewTap: _openReview,
                  ),
                  const SizedBox(height: 30),
                  ValueListenableBuilder<String>(
                    valueListenable: _selectedCategoryId,
                    builder: (context, selectedId, _) {
                      return Column(
                        children: [
                          _CategorySection(
                            categories: _categories,
                            selectedId: selectedId,
                            onSelected: (id) => _selectedCategoryId.value = id,
                            onViewAllTap: () =>
                                _openTab(1, const menu.MenuScreen()),
                          ),
                          const SizedBox(height: 28),
                          _PopularFoodSection(
                            foods: _visibleFoods(selectedId),
                            onFoodTap: _openFoodDetail,
                            onAddTap: _openFoodDetail,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  _buildDiscountBanner(),
                  _RecentViewedSection(
                    foods: _foods.take(4).toList(growable: false),
                    onFoodTap: (food) => _push(
                      detail.FoodDetailScreen(
                        foodId: food.foodId,
                        name: food.name,
                        description: food.description,
                        imageAsset: food.image,
                        basePrice: _parsePrice(food.price),
                        categoryId: food.categoryId,
                        categoryName: food.categoryName,
                        rating: food.rating,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : CanteenBottomNavBar(
              selectedIndex: _selectedTab,
              cartCount: _cartCount,
              onTap: _onBottomNavTap,
            ),
    );
  }

  int _parsePrice(String price) {
    return int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  List<_FoodData> _visibleFoods(String selectedId) {
    if (selectedId == CategoryFilterItem.allId) {
      return _foods;
    }
    final selectedCategory = _categories
        .where((item) => item.id == selectedId)
        .firstOrNull;
    return _foods
        .where(
          (food) =>
              food.categoryId == selectedId ||
              food.categoryName.toLowerCase() ==
                  selectedCategory?.label.toLowerCase(),
        )
        .toList(growable: false);
  }

  static String _formatMoney(int price) {
    final value = price.toString();
    final output = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      if (index > 0 && (value.length - index) % 3 == 0) output.write('.');
      output.write(value[index]);
    }
    return '$outputđ';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onQrTap,
  });

  final String userName;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 14, 18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $userName',
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hôm nay bạn muốn ăn gì?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xDFFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _BadgeIcon(
            icon: Icons.notifications_none_rounded,
            badge: notificationCount > 0 ? '$notificationCount' : null,
            onTap: onNotificationTap,
            inverted: true,
          ),
          const SizedBox(width: 8),
          _HeaderIcon(
            icon: Icons.qr_code_scanner_rounded,
            onTap: onQrTap,
            inverted: true,
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onExploreTap});

  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.primarySoft,
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 18, offset: Offset(0, 7)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 350;
          return Stack(
            children: [
              Positioned(
                right: -17,
                bottom: -2,
                top: 0,
                width: compact
                    ? constraints.maxWidth * .47
                    : constraints.maxWidth * .55,
                child: Image.asset(
                  'assets/images/chicken_rice.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      stops: const [0, .52, 1],
                      colors: [
                        AppColors.primarySoft,
                        AppColors.primarySoft.withValues(alpha: .95),
                        AppColors.primarySoft.withValues(alpha: .05),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 15,
                bottom: 10,
                child: Container(
                  width: 67,
                  height: 67,
                  decoration: BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _orange.withValues(alpha: .25),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GIẢM ĐẾN',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '20%',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.1,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ăn ngon mỗi ngày',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ưu đãi liền tay',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: onExploreTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Khám phá ngay →',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.cartCount,
    required this.onOrderTap,
    required this.onCartTap,
    required this.onHistoryTap,
    required this.onReviewTap,
  });

  final int cartCount;
  final VoidCallback onOrderTap;
  final VoidCallback onCartTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          _ActionItem(
            icon: Icons.room_service_rounded,
            iconColor: _orange,
            iconBackground: AppColors.primarySoft,
            label: 'Đặt món',
            caption: 'Giao tận nơi',
            onTap: onOrderTap,
          ),
          _ActionItem(
            icon: Icons.shopping_cart_rounded,
            iconColor: Color(0xFF17AF74),
            iconBackground: Color(0xFFE7F8F0),
            label: 'Giỏ hàng',
            caption: '$cartCount món',
            badge: cartCount > 0 ? '$cartCount' : null,
            onTap: onCartTap,
          ),
          _ActionItem(
            icon: Icons.receipt_long_rounded,
            iconColor: Color(0xFF348DE8),
            iconBackground: Color(0xFFEAF4FF),
            label: 'Lịch sử đơn',
            caption: 'Xem đơn hàng',
            onTap: onHistoryTap,
          ),
          _ActionItem(
            icon: Icons.star_rounded,
            iconColor: Color(0xFF7356C7),
            iconBackground: Color(0xFFF1EDFF),
            label: 'Đánh giá',
            caption: 'Góp ý dịch vụ',
            onTap: onReviewTap,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.caption,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 49,
                  width: 49,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -7,
                    child: _CountBadge(text: badge!),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12.5,
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              caption,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onViewAllTap,
  });

  final List<CategoryFilterItem> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onViewAllTap;

  static const demoCategories = [
    CategoryFilterItem.all,
    CategoryFilterItem(id: 'rice', label: 'Cơm'),
    CategoryFilterItem(id: 'noodles', label: 'Mì - Phở'),
    CategoryFilterItem(id: 'snack', label: 'Đồ ăn vặt'),
    CategoryFilterItem(id: 'drink', label: 'Nước uống'),
    CategoryFilterItem(id: 'dessert', label: 'Tráng miệng'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionTitle(title: 'Danh mục món ăn', onViewAllTap: onViewAllTap),
        const SizedBox(height: 17),
        CategoryFilterBar(
          categories: categories,
          selectedId: selectedId,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _PopularFoodSection extends StatelessWidget {
  const _PopularFoodSection({
    required this.foods,
    required this.onFoodTap,
    required this.onAddTap,
  });

  final List<_FoodData> foods;
  final ValueChanged<_FoodData> onFoodTap;
  final ValueChanged<_FoodData> onAddTap;

  static const demoFoods = [
    _FoodData(
      'Cơm gà nướng',
      '35.000đ',
      'assets/images/chicken_rice.jpg',
      categoryId: 'rice',
    ),
    _FoodData(
      'Phở bò tái',
      '30.000đ',
      'assets/images/pho.jpg',
      categoryId: 'noodles',
    ),
    _FoodData(
      'Mì trộn bò',
      '28.000đ',
      'assets/images/salad.jpg',
      categoryId: 'noodles',
    ),
    _FoodData(
      'Trà sữa trân',
      '15.000đ',
      'assets/images/pho.jpg',
      categoryId: 'drink',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(title: 'Món ăn phổ biến'),
        const SizedBox(height: 17),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: foods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _FoodCard(
              food: foods[index],
              onTap: () => onFoodTap(foods[index]),
              onAddTap: () => onAddTap(foods[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.onTap,
    required this.onAddTap,
  });

  final _FoodData food;
  final VoidCallback onTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 135,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0F1F3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0718253D),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: _FoodImage(
                  source: food.image,
                  height: 103,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 8, 0),
                child: Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 8, 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        food.price,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _orange,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onAddTap,
                      customBorder: const CircleBorder(),
                      child: Container(
                        height: 24,
                        width: 24,
                        decoration: const BoxDecoration(
                          color: _orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  const _DiscountCard({required this.voucher, required this.onClaimTap});

  final store.VoucherModel voucher;
  final VoidCallback onClaimTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F2),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: const BoxDecoration(
              color: Color(0xFFD5F3E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_activity_rounded,
              color: Color(0xFF3AB779),
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16804F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voucher.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          OutlinedButton(
            onPressed: onClaimTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF15925B),
              side: const BorderSide(color: Color(0xFF8CD9B3)),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Lấy mã ngay',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentViewedSection extends StatelessWidget {
  const _RecentViewedSection({required this.foods, required this.onFoodTap});

  final List<_FoodData> foods;
  final ValueChanged<_FoodData> onFoodTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(title: 'Gần đây bạn đã xem'),
        const SizedBox(height: 17),
        SizedBox(
          height: 101,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: foods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => onFoodTap(foods[index]),
                borderRadius: BorderRadius.circular(17),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: _FoodImage(
                    source: foods[index].image,
                    height: 101,
                    width: 127,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onViewAllTap});

  final String title;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ),
        if (onViewAllTap != null)
          TextButton(
            onPressed: onViewAllTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              foregroundColor: _orange,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Xem tất cả',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.inverted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: inverted
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 24,
        color: inverted ? Colors.white : _textPrimary,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.badge,
    required this.onTap,
    this.inverted = false,
  });

  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HeaderIcon(icon: icon, onTap: onTap, inverted: inverted),
        Positioned(right: -1, top: 3, child: AnimatedBadge(label: badge)),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 20, minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFEE3D45),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FoodData {
  const _FoodData(
    this.name,
    this.price,
    this.image, {
    this.foodId = '',
    this.categoryId = '',
    this.categoryName = '',
    this.description = '',
    this.rating = 0,
  });

  final String name;
  final String price;
  final String image;
  final String foodId;
  final String categoryId;
  final String categoryName;
  final String description;
  final double rating;
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({
    required this.source,
    required this.height,
    required this.width,
  });

  final String source;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      source,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: height,
        width: width,
        color: AppColors.primarySoft,
        child: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(title: 'Menu');
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(title: 'Giỏ hàng');
}

class FoodDetailScreen extends StatelessWidget {
  const FoodDetailScreen({super.key, required this.foodName});

  final String foodName;

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(title: foodName);
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
