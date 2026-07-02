import '../../../models/firestore_models.dart' as store;
import '../../../models/app_settings_model.dart';

enum PaymentMethod { cash, bankQr }

enum PaymentStatus { pending, paid, expired }

class PaymentOrderItem {
  const PaymentOrderItem({
    this.foodId = '',
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.imageAsset,
    this.note = '',
    this.basePrice,
    this.toppingTotal = 0,
    this.selectedToppings = const [],
  });

  final String foodId;
  final String name;
  final String description;
  final int quantity;
  final int unitPrice;
  final String imageAsset;
  final String note;
  final int? basePrice;
  final int toppingTotal;
  final List<store.ToppingModel> selectedToppings;

  int get total => unitPrice * quantity;
  int get resolvedBasePrice => basePrice ?? (unitPrice - toppingTotal);
}

class PaymentOrderModel {
  const PaymentOrderModel({
    required this.id,
    required this.items,
    this.serviceFee = 2000,
    this.voucherDiscount = 0,
    this.voucherCode,
    this.voucherId,
    this.voucherTitle,
  });

  final String id;
  final List<PaymentOrderItem> items;
  final int serviceFee;
  final int voucherDiscount;
  final String? voucherCode;
  final String? voucherId;
  final String? voucherTitle;

  int get subtotal => items.fold(0, (sum, item) => sum + item.total);

  int get total =>
      (subtotal + serviceFee - voucherDiscount).clamp(0, 1 << 31).toInt();

  String get transferDescription =>
      'ThanhToan${id.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
}

class QrPaymentModel {
  const QrPaymentModel({
    required this.amount,
    required this.description,
    required this.session,
    this.settings = PaymentSettingsModel.fallback,
  });

  static const String bankId = 'MB';
  static const String bankName = 'MB BANK';
  static const String accountNumber = '195989';
  static const String accountHolder = 'Nguyen Hai Nam';
  static const String qrAccountName = 'NguyenHaiNam';

  final int amount;
  final String description;
  final int session;
  final PaymentSettingsModel settings;

  String get displayBankName => settings.bankName;
  String get displayAccountNumber => settings.bankAccountNo;
  String get displayAccountName => settings.bankAccountName;

  Uri get imageUri => Uri.https(
    'img.vietqr.io',
    '/image/${settings.bankId}-${settings.bankAccountNo}-${settings.qrTemplate}.png',
    {
      'amount': '$amount',
      'addInfo': description,
      'accountName': settings.qrAccountName,
      'session': '$session',
    },
  );
}

String formatPaymentMoney(int amount) {
  final negative = amount < 0;
  final value = amount.abs().toString();
  final result = StringBuffer();
  for (var index = 0; index < value.length; index++) {
    if (index > 0 && (value.length - index) % 3 == 0) {
      result.write('.');
    }
    result.write(value[index]);
  }
  return '${negative ? '-' : ''}$resultđ';
}

const demoPaymentOrder = PaymentOrderModel(
  id: 'SC250522-000123',
  items: [
    PaymentOrderItem(
      name: 'Cơm gà xối mỡ',
      description: 'Cơm trắng, gà chiên giòn, dưa leo và sốt đặc biệt',
      quantity: 1,
      unitPrice: 32000,
      imageAsset: 'assets/images/chicken_rice.jpg',
    ),
    PaymentOrderItem(
      name: 'Trà tắc',
      description: 'Trà tắc mát lạnh',
      quantity: 1,
      unitPrice: 12000,
      imageAsset: 'assets/images/pho.jpg',
    ),
    PaymentOrderItem(
      name: 'Bánh flan',
      description: 'Bánh flan mềm mịn',
      quantity: 1,
      unitPrice: 10000,
      imageAsset: 'assets/images/salad.jpg',
    ),
  ],
);
