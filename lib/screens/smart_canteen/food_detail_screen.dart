import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/colors.dart';
import '../../core/utils/number_safety.dart';
import '../../core/widgets/app_food_image.dart';
import '../../models/firestore_models.dart' as store;
import '../../models/topping_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_topping_service.dart';
import 'cart_screen.dart';
import 'food_detail_controller.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({
    super.key,
    required this.foodId,
    required this.name,
    this.description = '',
    required this.imageAsset,
    required this.basePrice,
    required this.categoryId,
    this.categoryName = '',
    this.rating = 0,
    this.soldCount = 0,
    this.isAvailable = true,
    this.cartProvider,
  });

  final String foodId;
  final String name;
  final String description;
  final String imageAsset;
  final int basePrice;
  final String categoryId;
  final String categoryName;
  final double rating;
  final int soldCount;
  final bool isAvailable;
  final CartProvider? cartProvider;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedToppingIds = <String>{};
  late final FoodDetailController _controller;
  late final CartProvider _cartProvider;
  late final bool _ownsCartProvider;
  int _quantity = 1;
  bool _submitting = false;
  bool _scrolled = false;

  store.FoodModel? get _remoteFood => _controller.food;
  String get _name => _remoteFood?.name.trim().isNotEmpty == true
      ? _remoteFood!.name
      : widget.name;
  String get _description => _remoteFood?.description.trim().isNotEmpty == true
      ? _remoteFood!.description
      : widget.description;
  String get _image => _remoteFood?.imageUrl.trim().isNotEmpty == true
      ? _remoteFood!.imageUrl
      : widget.imageAsset;
  int get _basePrice => _remoteFood?.price ?? widget.basePrice;
  String get _categoryId => _remoteFood?.categoryId.trim().isNotEmpty == true
      ? _remoteFood!.categoryId
      : widget.categoryId;
  String get _categoryName => _displayCategoryName(
    _remoteFood?.categoryName.trim().isNotEmpty == true
        ? _remoteFood!.categoryName
        : widget.categoryName,
    _categoryId,
  );
  bool get _isAvailable => _remoteFood?.isAvailable ?? widget.isAvailable;
  double get _rating => _controller.averageRating > 0
      ? safeFiniteDouble(_controller.averageRating)
      : safeFiniteDouble(_remoteFood?.rating ?? widget.rating);
  int get _soldCount => _remoteFood?.soldCount ?? widget.soldCount;

  List<ToppingModel> get _availableToppings =>
      CategoryToppingService.optionsFor(_categoryId);
  List<ToppingModel> get _selectedToppings => _availableToppings
      .where((item) => _selectedToppingIds.contains(item.id))
      .toList(growable: false);
  int get _toppingTotal =>
      _selectedToppings.fold(0, (total, item) => total + item.price);
  int get _itemTotal => (_basePrice + _toppingTotal) * _quantity;

  @override
  void initState() {
    super.initState();
    _controller = FoodDetailController(foodId: widget.foodId)..bind();
    _ownsCartProvider = widget.cartProvider == null;
    _cartProvider = widget.cartProvider ?? CartProvider();
    if (_ownsCartProvider) _cartProvider.bindCurrentUser();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _noteController.dispose();
    _controller.dispose();
    if (_ownsCartProvider) _cartProvider.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final value = _scrollController.hasClients && _scrollController.offset > 36;
    if (value != _scrolled) setState(() => _scrolled = value);
  }

  Future<void> _addToCart() async {
    if (_submitting || !_isAvailable) return;
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      _showSnack('Vui lòng đăng nhập để thêm vào giỏ hàng.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await HapticFeedback.selectionClick();
      await _cartProvider.addItem(
        store.CartItemModel(
          foodId: widget.foodId,
          name: _name,
          imageUrl: _image,
          basePrice: _basePrice,
          quantity: _quantity,
          note: _noteController.text.trim(),
          selectedToppings: _selectedToppings
              .map(
                (item) => store.ToppingModel(
                  id: item.id,
                  name: item.name,
                  price: item.price,
                ),
              )
              .toList(growable: false),
          toppingTotal: _toppingTotal,
          itemTotal: _itemTotal,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_name đã được thêm vào giỏ hàng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/menu');
      }
    } catch (error) {
      if (mounted) _showSnack('Không thể thêm món vào giỏ. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  void _toggleTopping(ToppingModel item) {
    setState(() {
      final group = _groupFor(item);
      if (_selectedToppingIds.contains(item.id)) {
        _selectedToppingIds.remove(item.id);
      } else {
        if (group.singleChoice) {
          for (final option in group.items) {
            _selectedToppingIds.remove(option.id);
          }
        }
        _selectedToppingIds.add(item.id);
      }
    });
  }

  void _changeQuantity(int delta) {
    final next = (_quantity + delta).clamp(1, 99).toInt();
    if (next == _quantity) return;
    HapticFeedback.selectionClick();
    setState(() => _quantity = next);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _cartProvider]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(child: _HeroImageSection(screen: this)),
                  SliverToBoxAdapter(child: _FoodInfoSection(screen: this)),
                  SliverToBoxAdapter(child: _ToppingSection(screen: this)),
                  SliverToBoxAdapter(child: _NoteSection(screen: this)),
                  SliverToBoxAdapter(child: _ReviewSection(screen: this)),
                  const SliverToBoxAdapter(child: SizedBox(height: 118)),
                ],
              ),
              _FloatingHeader(screen: this),
            ],
          ),
          bottomNavigationBar: _BottomActionBar(screen: this),
        );
      },
    );
  }

  List<_ToppingGroup> _toppingGroups() {
    final toppings = _availableToppings;
    final spice = toppings
        .where((item) => item.id.contains('spicy'))
        .toList(growable: false);
    final ice = toppings
        .where((item) => item.id.contains('ice'))
        .toList(growable: false);
    final sugar = toppings
        .where((item) => item.id.contains('sugar'))
        .toList(growable: false);
    final specialIds = {
      ...spice,
      ...ice,
      ...sugar,
    }.map((item) => item.id).toSet();
    final optional = toppings
        .where((item) => !specialIds.contains(item.id))
        .toList(growable: false);
    return [
      if (optional.isNotEmpty)
        _ToppingGroup(title: 'Chọn topping', items: optional),
      if (spice.isNotEmpty)
        _ToppingGroup(title: 'Mức độ cay', items: spice, singleChoice: true),
      if (ice.isNotEmpty)
        _ToppingGroup(title: 'Chọn mức đá', items: ice, singleChoice: true),
      if (sugar.isNotEmpty)
        _ToppingGroup(
          title: 'Chọn mức đường',
          items: sugar,
          singleChoice: true,
        ),
    ];
  }

  _ToppingGroup _groupFor(ToppingModel item) {
    return _toppingGroups().firstWhere(
      (group) => group.items.any((option) => option.id == item.id),
      orElse: () => _ToppingGroup(title: 'Tùy chọn', items: [item]),
    );
  }

  String _displayCategoryName(String name, String id) {
    final value = name.trim();
    if (value.isNotEmpty && !value.startsWith('cat_')) return value;
    return switch (id.trim().toLowerCase()) {
      'cat_rice' || 'rice' => 'Cơm',
      'cat_noodle' || 'noodle' || 'mi' => 'Mì - Phở',
      'cat_pho' || 'pho' => 'Phở',
      'cat_snack' || 'snack' => 'Đồ ăn vặt',
      'cat_drink' || 'drink' => 'Nước uống',
      _ => 'Món ăn',
    };
  }

  String _money(int amount) {
    final raw = amount.toString();
    return '${raw.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }

  String _soldLabel(int value) {
    if (value >= 1000) {
      final compact = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
      return 'Đã bán ${compact}k';
    }
    return value > 0 ? 'Đã bán $value' : 'Món mới';
  }
}

class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: top + 58,
      padding: EdgeInsets.fromLTRB(12, top + 6, 12, 6),
      decoration: BoxDecoration(
        color: screen._scrolled
            ? AppColors.surface.withValues(alpha: 0.96)
            : Colors.transparent,
        boxShadow: screen._scrolled ? AppColors.cardShadow : null,
      ),
      child: Row(
        children: [
          _GlassIconButton(
            semanticLabel: 'Quay lại',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.maybePop(context),
            dark: !screen._scrolled,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedOpacity(
              opacity: screen._scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Text(
                screen._name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _GlassIconButton(
                semanticLabel: 'Giỏ hàng',
                icon: Icons.shopping_cart_outlined,
                dark: !screen._scrolled,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                ),
              ),
              if (screen._cartProvider.itemCount > 0)
                Positioned(
                  right: -2,
                  top: -3,
                  child: AnimatedScale(
                    scale: 1,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF2D2D),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${screen._cartProvider.itemCount.clamp(1, 99)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroImageSection extends StatelessWidget {
  const _HeroImageSection({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 74, 16, 0),
      child: Hero(
        tag: 'food-image-${screen.widget.foodId}',
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.025, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) => Transform.scale(
              scale: safeFiniteDouble(scale, fallback: 1),
              child: child,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 282,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppFoodImage(source: screen._image, fit: BoxFit.cover),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.58),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricPill(
                            icon: Icons.star_rounded,
                            label: screen._rating > 0
                                ? screen._rating.toStringAsFixed(1)
                                : 'Chưa có đánh giá',
                          ),
                          _MetricPill(
                            icon: Icons.local_fire_department_rounded,
                            label: screen._soldLabel(screen._soldCount),
                          ),
                          const _MetricPill(
                            icon: Icons.timer_outlined,
                            label: '15 phút',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodInfoSection extends StatelessWidget {
  const _FoodInfoSection({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    final oldPrice = screen._basePrice >= 45000
        ? (screen._basePrice * 1.16).round()
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoftBadge(label: screen._categoryName),
                if (screen._soldCount > 100)
                  const _SoftBadge(label: 'Best Seller', hot: true),
                if (!screen._isAvailable)
                  const _SoftBadge(label: 'Tạm hết món', danger: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              screen._name,
              style: const TextStyle(
                fontSize: 27,
                height: 1.12,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  screen._money(screen._basePrice),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                if (oldPrice != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    screen._money(oldPrice),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (screen._description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                screen._description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToppingSection extends StatelessWidget {
  const _ToppingSection({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    final groups = screen._toppingGroups();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tùy chọn món',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (groups.isEmpty)
            const _EmptyCard(text: 'Món này chưa có topping tùy chọn.')
          else
            for (final group in groups) ...[
              _ToppingGroupCard(group: group, screen: screen),
              const SizedBox(height: 12),
            ],
          _QuantitySelector(screen: screen),
        ],
      ),
    );
  }
}

class _ToppingGroupCard extends StatelessWidget {
  const _ToppingGroupCard({required this.group, required this.screen});

  final _ToppingGroup group;
  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (group.singleChoice) const _TinyHint(text: 'Chọn 1'),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: group.items
                .map((item) {
                  final selected = screen._selectedToppingIds.contains(item.id);
                  return _ToppingChip(
                    item: item,
                    selected: selected,
                    price: item.price > 0
                        ? '+${screen._money(item.price)}'
                        : '',
                    onTap: () => screen._toggleTopping(item),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Số lượng',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.remove_rounded,
            enabled: screen._quantity > 1,
            onTap: () => screen._changeQuantity(-1),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: SizedBox(
              key: ValueKey(screen._quantity),
              width: 42,
              child: Text(
                '${screen._quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            enabled: screen._quantity < 99,
            onTap: () => screen._changeQuantity(1),
          ),
        ],
      ),
    );
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
        ),
        child: TextField(
          controller: screen._noteController,
          maxLength: 120,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'Ghi chú cho món ăn',
            hintText: 'Ví dụ: ít cay, không hành...',
            alignLabelWithHint: true,
            border: InputBorder.none,
            counterStyle: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    final reviews = screen._controller.reviews.take(2).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Đánh giá món ăn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: reviews.isEmpty ? null : () {},
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB020)),
                const SizedBox(width: 5),
                Text(
                  screen._rating > 0
                      ? '${screen._rating.toStringAsFixed(1)} (${screen._controller.reviewCount} đánh giá)'
                      : 'Chưa có đánh giá',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              const Text(
                'Hãy là người đầu tiên đánh giá món này sau khi đặt hàng.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              )
            else
              for (final review in reviews) ...[
                _ReviewPreview(review: review),
                if (review != reviews.last)
                  const Divider(height: 18, color: AppColors.divider),
              ],
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${screen._quantity} món',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          screen._money(screen._itemTotal),
                          key: ValueKey(screen._itemTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _GradientAddButton(screen: screen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientAddButton extends StatelessWidget {
  const _GradientAddButton({required this.screen});

  final _FoodDetailScreenState screen;

  @override
  Widget build(BuildContext context) {
    final enabled = screen._isAvailable && !screen._submitting;
    return AnimatedOpacity(
      opacity: screen._isAvailable ? 1 : 0.55,
      duration: const Duration(milliseconds: 180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.brandGradient : null,
          color: enabled ? null : AppColors.textTertiary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled ? AppColors.cardShadow : null,
        ),
        child: FilledButton.icon(
          onPressed: enabled ? screen._addToCart : null,
          icon: screen._submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_shopping_cart_rounded, size: 19),
          label: Text(screen._isAvailable ? 'Thêm vào giỏ' : 'Tạm hết'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(156, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
    required this.dark,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: dark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.86),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  icon,
                  color: dark ? Colors.white : AppColors.textPrimary,
                  size: 21,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    this.hot = false,
    this.danger = false,
  });

  final String label;
  final bool hot;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.error
        : hot
        ? AppColors.primary
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ToppingChip extends StatelessWidget {
  const _ToppingChip({
    required this.item,
    required this.selected,
    required this.price,
    required this.onTap,
  });

  final ToppingModel item;
  final bool selected;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.02 : 1,
      duration: const Duration(milliseconds: 160),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.brandGradient : null,
              color: selected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? Colors.transparent : AppColors.divider,
              ),
              boxShadow: selected ? AppColors.cardShadow : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('selected'),
                          color: Colors.white,
                          size: 17,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                if (selected) const SizedBox(width: 6),
                Text(
                  item.name,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                if (price.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    price,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.38,
      duration: const Duration(milliseconds: 150),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _TinyHint extends StatelessWidget {
  const _TinyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({required this.review});

  final store.ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            review.userId.isEmpty ? 'U' : review.userId[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 15,
                      color: const Color(0xFFFFB020),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                review.comment.isEmpty ? 'Đánh giá tốt.' : review.comment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _ToppingGroup {
  const _ToppingGroup({
    required this.title,
    required this.items,
    this.singleChoice = false,
  });

  final String title;
  final List<ToppingModel> items;
  final bool singleChoice;
}
