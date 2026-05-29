import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/widgets/app_food_image.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../models/firestore_models.dart' as store;
import '../../providers/cart_provider.dart';
import 'cart_screen.dart' as cart;
import 'food_detail_screen.dart';
import 'menu_provider.dart';
import 'notifications/notification_screen.dart';
import 'profile/profile_screen.dart';
import 'smart_canteen_home_screen.dart' show SmartCanteenHomeScreen;
import 'widgets/canteen_bottom_nav_bar.dart';
import 'widgets/category_filter_bar.dart';

const _orange = AppColors.primary;
const _background = Color(0xFFFDFDFE);
const _surface = Colors.white;
const _textPrimary = Color(0xFF171A23);
const _textSecondary = Color(0xFF727783);
const _border = Color(0xFFF0F1F4);
const _shadow = Color(0x0C18253D);

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.embedded = false, this.onTabSelected});

  final bool embedded;
  final ValueChanged<int>? onTabSelected;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const _menuStorageKey = PageStorageKey<String>('menu_scroll_key');

  late final CartProvider _cartProvider;
  late final MenuProvider _menuProvider;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _preloadedImageUrls = <String>{};
  DateTime? _loadingStartedAt;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    _cartProvider = CartProvider()..addListener(_onCartChanged);
    _menuProvider = MenuProvider()..addListener(_onMenuStateChanged);
    _loadingStartedAt = DateTime.now();
    _showSkeleton = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final provider = _menuProvider;
      if (provider.foodState == FoodState.loading && !_showSkeleton) {
        setState(() => _showSkeleton = true);
      }
    });
    unawaited(_cartProvider.bindCurrentUser());
    unawaited(_menuProvider.initialize());
  }

  static String _formatMoney(int value) {
    final digits = value.toString();
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
      result.write(digits[index]);
    }
    return '$resultđ';
  }

  @override
  void dispose() {
    _cartProvider.removeListener(_onCartChanged);
    _cartProvider.dispose();
    _menuProvider
      ..removeListener(_onMenuStateChanged)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _onMenuStateChanged() {
    if (!mounted) return;
    final state = _menuProvider.foodState;
    if (state != FoodState.loading && _showSkeleton) {
      final elapsed = DateTime.now().difference(
        _loadingStartedAt ?? DateTime.now(),
      );
      if (elapsed < const Duration(milliseconds: 300)) {
        Future.delayed(const Duration(milliseconds: 300) - elapsed, () {
          if (mounted) setState(() => _showSkeleton = false);
        });
      } else {
        setState(() => _showSkeleton = false);
      }
    } else {
      setState(() {});
    }
  }

  Future<void> _preloadPopularImages(
    BuildContext context,
    List<store.FoodModel> foods,
  ) async {
    final candidates = foods
        .where((item) => item.imageUrl.startsWith('http'))
        .take(6)
        .map((item) => item.imageUrl)
        .toSet();
    for (final url in candidates) {
      if (_preloadedImageUrls.contains(url)) continue;
      await precacheImage(NetworkImage(url), context);
      _preloadedImageUrls.add(url);
    }
  }

  int get _cartCount => _cartProvider.itemCount;

  void _openCart() {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(2);
      return;
    }
    AppNavigator.push<void>(context, builder: (_) => const cart.CartScreen());
  }

  void _openFood(FoodData food) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: FoodDetailScreen(
            name: food.name,
            description: food.description,
            imageAsset: food.image,
            basePrice: food.priceValue,
            foodId: food.foodId,
            categoryId: food.categoryId,
            categoryName: food.categoryName,
            rating: food.rating,
            cartProvider: _cartProvider,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }
    switch (index) {
      case 0:
        AppNavigator.replace<void>(
          context,
          builder: (_) => const SmartCanteenHomeScreen(),
        );
        return;
      case 2:
        _openCart();
        return;
      case 3:
        AppNavigator.push<void>(
          context,
          builder: (_) => const NotificationScreen(),
        );
        return;
      case 4:
        AppNavigator.push<void>(
          context,
          builder: (_) => ProfileScreen(cartCount: _cartCount),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              cartCount: _cartCount,
              onBack: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(0);
                } else {
                  Navigator.pop(context);
                }
              },
              onCartTap: _openCart,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _menuProvider,
                builder: (context, _) {
                  final visibleFoods = _menuProvider.visibleFoods;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || visibleFoods.isEmpty) return;
                    unawaited(_preloadPopularImages(context, visibleFoods));
                  });
                  return CustomScrollView(
                    key: _menuStorageKey,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        sliver: SliverToBoxAdapter(
                          child: _SearchFilter(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _menuProvider.onSearchChanged,
                            onFilterTap: () {},
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
                        sliver: SliverToBoxAdapter(
                          child: CategoryFilterBar(
                            categories: _menuProvider.categories,
                            selectedId: _menuProvider.selectedCategoryId,
                            onSelected: _menuProvider.selectCategory,
                          ),
                        ),
                      ),
                      if (_showSkeleton)
                        const _FoodSkeletonList()
                      else if (_menuProvider.foodState == FoodState.error)
                        SliverToBoxAdapter(
                          child: _StateMessage(
                            text:
                                _menuProvider.errorMessage.isEmpty
                                    ? 'Không thể tải dữ liệu món ăn'
                                    : _menuProvider.errorMessage,
                          ),
                        )
                      else if (visibleFoods.isEmpty)
                        const SliverToBoxAdapter(
                          child: _StateMessage(text: 'Không có món phù hợp'),
                        )
                      else
                        _FoodList(
                          foods: visibleFoods.map(FoodData.fromModel).toList(),
                          onFoodTap: _openFood,
                          onAddTap: _openFood,
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : CanteenBottomNavBar(
              selectedIndex: 1,
              cartCount: _cartCount,
              onTap: _onBottomNavTap,
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cartCount,
    required this.onBack,
    required this.onCartTap,
  });

  final int cartCount;
  final VoidCallback onBack;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 8, 13, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _textPrimary,
            iconSize: 22,
          ),
          const Expanded(
            child: Text(
              'Danh sách món ăn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: _textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: _BadgeIcon(
              icon: Icons.shopping_cart_outlined,
              badge: cartCount > 0 ? '$cartCount' : null,
              onTap: onCartTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchFilter extends StatelessWidget {
  const _SearchFilter({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 25, color: _textSecondary),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Tìm món ăn, đồ uống...',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: _textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 13),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(13),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: _textPrimary, size: 23),
                SizedBox(width: 5),
                Text(
                  'Bộ lọc',
                  style: TextStyle(fontSize: 14, color: _textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodList extends StatelessWidget {
  const _FoodList({
    required this.foods,
    required this.onFoodTap,
    required this.onAddTap,
  });

  final List<FoodData> foods;
  final ValueChanged<FoodData> onFoodTap;
  final ValueChanged<FoodData> onAddTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList.separated(
        itemCount: foods.length,
        separatorBuilder: (_, _) => const SizedBox(height: 11),
        itemBuilder: (context, index) => _FoodCard(
          food: foods[index],
          onTap: () => onFoodTap(foods[index]),
          onAddTap: () => onAddTap(foods[index]),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.onTap,
    required this.onAddTap,
  });

  final FoodData food;
  final VoidCallback onTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 128,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(color: _shadow, blurRadius: 15, offset: Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AppFoodImage(
                  source: food.image,
                  width: 119,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.7,
                        height: 1.45,
                        color: _textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      food.price,
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onAddTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEADB)),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: _orange,
                    size: 27,
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

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon),
          iconSize: 29,
          color: _textPrimary,
        ),
        Positioned(top: 1, right: 1, child: AnimatedBadge(label: badge)),
      ],
    );
  }
}

class FoodData {
  const FoodData({
    this.foodId = '',
    this.categoryId = '',
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    this.categoryName = '',
    this.rating = 0,
  });

  final String foodId;
  final String categoryId;
  final String name;
  final String description;
  final String price;
  final String image;
  final String categoryName;
  final double rating;

  int get priceValue => int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));

  factory FoodData.fromModel(store.FoodModel item) => FoodData(
    foodId: item.id,
    categoryId: item.categoryId,
    name: item.name,
    description: item.description,
    price: _MenuScreenState._formatMoney(item.price),
    image: item.imageUrl,
    categoryName: item.categoryName,
    rating: item.rating,
  );
}

class _FoodSkeletonList extends StatelessWidget {
  const _FoodSkeletonList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList.separated(
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 11),
        itemBuilder: (_, _) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          SizedBox(width: 7),
          _SkeletonBox(width: 119, height: 112, radius: 11),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                _SkeletonBox(width: 120, height: 16, radius: 8),
                SizedBox(height: 10),
                _SkeletonBox(width: 180, height: 12, radius: 8),
                SizedBox(height: 6),
                _SkeletonBox(width: 140, height: 12, radius: 8),
                Spacer(),
                _SkeletonBox(width: 90, height: 16, radius: 8),
                SizedBox(height: 14),
              ],
            ),
          ),
          _SkeletonBox(width: 42, height: 42, radius: 12),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.8),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBF0),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 40),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}
