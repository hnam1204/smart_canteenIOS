import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/widgets/app_food_image.dart';
import '../../models/firestore_models.dart' as store;
import '../../providers/cart_provider.dart';
import '../../providers/voucher_provider.dart';
import 'cart/widgets/voucher_bottom_sheet.dart';
import 'menu_screen.dart' show MenuScreen;
import 'notifications/notification_screen.dart';
import 'payment_screen.dart';
import 'payment/payment_model.dart';
import 'profile/profile_screen.dart';
import 'smart_canteen_home_screen.dart' show SmartCanteenHomeScreen;
import 'widgets/canteen_bottom_nav_bar.dart';

const _orange = AppColors.primary;
const _orangeSoft = AppColors.primarySoft;
const _green = Color(0xFF15803D);
const _greenSoft = Color(0xFFF0F9F3);
const _background = Color(0xFFFDFDFE);
const _surface = Colors.white;
const _textPrimary = Color(0xFF171A23);
const _textSecondary = Color(0xFF727783);
const _border = Color(0xFFF0F1F4);
const _shadow = Color(0x0B18253D);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.embedded = false, this.onTabSelected});

  final bool embedded;
  final ValueChanged<int>? onTabSelected;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartProvider _cartProvider;
  late final VoucherProvider _voucherProvider;

  static const _previewItems = [
    store.CartItemModel(
      foodId: 'chicken-rice',
      name: 'Cơm gà xối mỡ',
      basePrice: 32000,
      quantity: 1,
      imageUrl: 'assets/images/chicken_rice.jpg',
    ),
    store.CartItemModel(
      foodId: 'kumquat-tea',
      name: 'Trà tắc',
      basePrice: 12000,
      quantity: 1,
      imageUrl: 'assets/images/pho.jpg',
    ),
    store.CartItemModel(
      foodId: 'flan',
      name: 'Bánh flan',
      basePrice: 10000,
      quantity: 1,
      imageUrl: 'assets/images/salad.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cartProvider = CartProvider(
      initialItems: Firebase.apps.isEmpty ? _previewItems : const [],
    )..addListener(_onCartChanged);
    _voucherProvider = VoucherProvider()..addListener(_onCartChanged);
    unawaited(_cartProvider.bindCurrentUser());
    _voucherProvider.bind();
  }

  @override
  void dispose() {
    _cartProvider.removeListener(_onCartChanged);
    _voucherProvider.removeListener(_onCartChanged);
    _cartProvider.dispose();
    _voucherProvider.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  List<_CartItemData> get _items => _cartProvider.items
      .map(
        (item) => _CartItemData(
          foodId: item.foodId,
          name: item.name,
          description: [
            if (item.selectedToppings.isNotEmpty)
              item.selectedToppings.map((topping) => topping.name).join(', '),
            if (item.note.isNotEmpty) 'Ghi chú: ${item.note}',
          ].join('\n'),
          basePrice: item.basePrice,
          toppingTotal: item.toppingTotal,
          note: item.note,
          selectedToppings: item.selectedToppings,
          total: item.total,
          quantity: item.quantity,
          image: item.imageUrl,
        ),
      )
      .toList(growable: false);

  int get _cartCount => _cartProvider.itemCount;
  int get _subtotal => _cartProvider.subtotal;
  int get _total => _cartProvider.hasItems ? _cartProvider.total : 0;

  String _formatPrice(int value) {
    final text = value.toString();
    final result = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) result.write('.');
      result.write(text[i]);
    }
    return '$resultđ';
  }

  void _removeItem(int index) {
    unawaited(_cartProvider.removeAt(index));
  }

  void _clearCart() {
    unawaited(_cartProvider.clear());
  }

  void _increaseItem(int index) {
    unawaited(_cartProvider.increaseAt(index));
  }

  void _decreaseItem(int index) {
    unawaited(_cartProvider.decreaseAt(index));
  }

  Future<void> _showVoucher() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => VoucherBottomSheet(
        vouchers: _voucherProvider.validFor(_subtotal),
        subtotal: _subtotal,
        selectedVoucherId: _cartProvider.selectedVoucher?.id,
        onApply: (voucher) async {
          final applied = await _cartProvider.applyVoucher(voucher);
          if (!sheetContext.mounted) return;
          Navigator.pop(sheetContext);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                applied ? 'Đã áp dụng ${voucher.code}' : 'Voucher không hợp lệ',
              ),
            ),
          );
        },
        onRemove: () {
          _cartProvider.removeVoucher();
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _checkout() {
    AppNavigator.push<void>(
      context,
      builder: (_) => PaymentScreen(
        order: PaymentOrderModel(
          id: 'SC${DateTime.now().millisecondsSinceEpoch}',
          items: _items
              .map(
                (item) => PaymentOrderItem(
                  foodId: item.foodId,
                  name: item.name,
                  description: item.description,
                  quantity: item.quantity,
                  unitPrice: item.total ~/ item.quantity,
                  imageAsset: item.image,
                  note: item.note,
                  basePrice: item.basePrice,
                  toppingTotal: item.toppingTotal,
                  selectedToppings: item.selectedToppings,
                ),
              )
              .toList(growable: false),
          serviceFee: _cartProvider.deliveryFee,
          voucherDiscount: _cartProvider.voucherDiscount,
          voucherCode: _cartProvider.voucherCode,
          voucherId: _cartProvider.selectedVoucher?.id,
          voucherTitle: _cartProvider.selectedVoucher?.title,
        ),
      ),
    );
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
              onBack: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(0);
                } else {
                  Navigator.pop(context);
                }
              },
              onClear: _items.isEmpty ? null : _clearCart,
            ),
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyCart()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 11, 18, 20),
                      child: Column(
                        children: [
                          const _CartNotice(),
                          const SizedBox(height: 17),
                          for (
                            var index = 0;
                            index < _items.length;
                            index++
                          ) ...[
                            _CartItemCard(
                              item: _items[index],
                              formattedPrice: _formatPrice(_items[index].total),
                              onRemove: () => _removeItem(index),
                              onDecrease: () => _decreaseItem(index),
                              onIncrease: () => _increaseItem(index),
                            ),
                            if (index != _items.length - 1)
                              const SizedBox(height: 11),
                          ],
                          const SizedBox(height: 16),
                          _VoucherCard(
                            selectedCode: _cartProvider.voucherCode,
                            onTap: _showVoucher,
                            onRemove: _cartProvider.voucherCode == null
                                ? null
                                : _cartProvider.removeVoucher,
                          ),
                          const SizedBox(height: 18),
                          _PriceSummary(
                            subtotal: _formatPrice(_subtotal),
                            serviceFee: _formatPrice(_cartProvider.deliveryFee),
                            voucherDiscount: _cartProvider.voucherDiscount > 0
                                ? _formatPrice(_cartProvider.voucherDiscount)
                                : null,
                            total: _formatPrice(_total),
                          ),
                          const SizedBox(height: 15),
                          _PointCard(points: _total ~/ 1000),
                          const SizedBox(height: 18),
                          _CheckoutButton(onPressed: _checkout),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : CanteenBottomNavBar(
              selectedIndex: 2,
              cartCount: _cartCount,
              onTap: (index) {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(index);
                  return;
                }
                if (index == 0) {
                  AppNavigator.replace<void>(
                    context,
                    builder: (_) => const SmartCanteenHomeScreen(),
                  );
                }
                if (index == 1) {
                  AppNavigator.replace<void>(
                    context,
                    builder: (_) => const MenuScreen(),
                  );
                }
                if (index == 3) {
                  AppNavigator.push<void>(
                    context,
                    builder: (_) => NotificationScreen(cartCount: _cartCount),
                  );
                }
                if (index == 4) {
                  AppNavigator.push<void>(
                    context,
                    builder: (_) => ProfileScreen(cartCount: _cartCount),
                  );
                }
              },
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onClear});

  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 10),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: _textPrimary,
              iconSize: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'Giỏ hàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.25,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded),
              iconSize: 26,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartNotice extends StatelessWidget {
  const _CartNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: _greenSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: _green, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(text: 'Đơn hàng của bạn sẽ được giữ trong '),
                  TextSpan(
                    text: '15 phút',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.formattedPrice,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
  });

  final _CartItemData item;
  final String formattedPrice;
  final VoidCallback onRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;

        return Container(
          height: compact ? 185 : 151,
          padding: const EdgeInsets.all(12),
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
                  source: item.image,
                  width: compact ? 92 : 118,
                  height: 126,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.2,
                              color: _textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onRemove,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 4),
                            child: Icon(
                              Icons.close_rounded,
                              color: Color(0xFF999DA5),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: _textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (compact) ...[
                      Text(
                        formattedPrice,
                        style: const TextStyle(
                          color: _orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _QuantityStepper(
                          quantity: item.quantity,
                          onDecrease: onDecrease,
                          onIncrease: onIncrease,
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Text(
                            formattedPrice,
                            style: const TextStyle(
                              color: _orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _QuantityStepper(
                            quantity: item.quantity,
                            onDecrease: onDecrease,
                            onIncrease: onIncrease,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: onDecrease,
            child: const SizedBox(
              width: 34,
              height: 40,
              child: Icon(Icons.remove_rounded, size: 20),
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          InkWell(
            onTap: onIncrease,
            child: const SizedBox(
              width: 34,
              height: 40,
              child: Icon(Icons.add_rounded, size: 21),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.selectedCode,
    required this.onTap,
    required this.onRemove,
  });

  final String? selectedCode;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.percent_rounded, color: Color(0xFFED5260)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mã giảm giá',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  selectedCode ?? 'Chọn hoặc nhập mã',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: selectedCode == null ? _textSecondary : _orange,
                    fontWeight: selectedCode == null
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Bỏ mã',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: _orange),
            child: const Row(
              children: [
                Text(
                  'Chọn mã',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.subtotal,
    required this.serviceFee,
    required this.voucherDiscount,
    required this.total,
  });

  final String subtotal;
  final String serviceFee;
  final String? voucherDiscount;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PriceRow(label: 'Tạm tính', value: subtotal),
        const SizedBox(height: 17),
        _PriceRow(label: 'Phí dịch vụ', value: serviceFee, withInfo: true),
        if (voucherDiscount != null) ...[
          const SizedBox(height: 17),
          _PriceRow(
            label: 'Voucher',
            value: '-$voucherDiscount',
            valueColor: _green,
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Divider(height: 1, color: _border),
        ),
        Row(
          children: [
            const Text(
              'Tổng cộng',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              total,
              style: const TextStyle(
                color: _orange,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.withInfo = false,
    this.valueColor = _textPrimary,
  });

  final String label;
  final String value;
  final bool withInfo;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _textPrimary)),
        if (withInfo) ...[
          const SizedBox(width: 5),
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: _textSecondary,
          ),
        ],
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 10, 13),
      decoration: BoxDecoration(
        color: _greenSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: _green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: _textPrimary, fontSize: 13),
                children: [
                  const TextSpan(text: 'Bạn sẽ được tích '),
                  TextSpan(
                    text: '$points điểm',
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' sau khi thanh toán'),
                ],
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _green),
        ],
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tiến hành thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 94,
            width: 94,
            decoration: const BoxDecoration(
              color: _orangeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: _orange,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Giỏ hàng đang trống',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm món ăn yêu thích của bạn.',
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _CartItemData {
  _CartItemData({
    this.foodId = '',
    required this.name,
    required this.description,
    required this.basePrice,
    required this.toppingTotal,
    required this.note,
    required this.selectedToppings,
    required this.total,
    required this.quantity,
    required this.image,
  });

  final String foodId;
  final String name;
  final String description;
  final int basePrice;
  final int toppingTotal;
  final String note;
  final List<store.ToppingModel> selectedToppings;
  final int total;
  int quantity;
  final String image;
}
