import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

DateTime _date(dynamic value, [DateTime? fallback]) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? (fallback ?? DateTime(2000));
  }
  return fallback ?? DateTime(2000);
}

int _int(dynamic value) => value is num ? value.toInt() : 0;
double _double(dynamic value) => value is num ? value.toDouble() : 0;
String _string(dynamic value) => value?.toString() ?? '';
bool _bool(dynamic value, [bool fallback = false]) =>
    value is bool ? value : fallback;
List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : const [];
class ToppingModel {
  const ToppingModel({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final int price;

  factory ToppingModel.fromMap(Map<String, dynamic> data) => ToppingModel(
    id: _string(data['id']),
    name: _string(data['name']),
    price: _int(data['price']),
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price};
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.points,
    required this.role,
    required this.createdAt,
    this.studentId = '',
    this.department = '',
    this.address = '',
    this.note = '',
    this.gender = '',
    this.dateOfBirth,
    this.orderCount = 0,
    this.totalSpent = 0,
    this.memberTier = '',
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final int points;
  final String role;
  final DateTime createdAt;
  final String studentId;
  final String department;
  final String address;
  final String note;
  final String gender;
  final DateTime? dateOfBirth;
  final int orderCount;
  final int totalSpent;
  final String memberTier;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    debugPrint('User document: ${doc.data()}');
    final data = doc.data() ?? const {};
    final uid = _string(data['uid']).isEmpty ? doc.id : _string(data['uid']);
    final rawAvatar = _string(data['avatarUrl']);
    final avatarUrl = rawAvatar.isNotEmpty
        ? rawAvatar
        : 'https://api.dicebear.com/9.x/personas/svg?seed=$uid';
    return UserModel(
      uid: uid,
      fullName: _string(data['fullName']),
      email: _string(data['email']),
      phone: _string(data['phone']),
      avatarUrl: avatarUrl,
      points: _int(data['points']),
      role: _string(data['role']).isEmpty ? 'customer' : _string(data['role']),
      createdAt: _date(data['createdAt']),
      studentId: _string(data['studentId']),
      department: _string(data['department']),
      address: _string(data['address']),
      note: _string(data['note']),
      gender: _string(data['gender']),
      dateOfBirth: data.containsKey('dateOfBirth')
          ? _date(data['dateOfBirth'])
          : null,
      orderCount: _int(data['orderCount'] ?? data['totalOrders']),
      totalSpent: _int(data['totalSpent']),
      memberTier: _string(data['memberTier']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'points': points,
    'role': role,
    'createdAt': Timestamp.fromDate(createdAt),
    'studentId': studentId,
    'department': department,
    'address': address,
    'note': note,
    'gender': gender,
    if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
    'orderCount': orderCount,
    'totalOrders': orderCount,
    'totalSpent': totalSpent,
    'memberTier': memberTier,
  };

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    int? points,
    String? role,
    String? studentId,
    String? department,
    String? address,
    String? note,
    String? gender,
    DateTime? dateOfBirth,
    int? orderCount,
    int? totalSpent,
    String? memberTier,
  }) => UserModel(
    uid: uid,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    points: points ?? this.points,
    role: role ?? this.role,
    createdAt: createdAt,
    studentId: studentId ?? this.studentId,
    department: department ?? this.department,
    address: address ?? this.address,
    note: note ?? this.note,
    gender: gender ?? this.gender,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    orderCount: orderCount ?? this.orderCount,
    totalSpent: totalSpent ?? this.totalSpent,
    memberTier: memberTier ?? this.memberTier,
  );
}

class FoodModel {
  const FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.isAvailable,
    required this.rating,
    required this.soldCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final bool isAvailable;
  final double rating;
  final int soldCount;
  final DateTime createdAt;

  factory FoodModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return FoodModel(
      id: _string(data['id']).isEmpty ? doc.id : _string(data['id']),
      name: _string(data['name']),
      description: _string(data['description']),
      price: _int(data['price']),
      imageUrl: _string(data['imageUrl']),
      categoryId: _string(data['categoryId']),
      categoryName: _string(data['categoryName']),
      isAvailable: _bool(data['isAvailable'], true),
      rating: _double(data['rating']),
      soldCount: _int(data['soldCount']),
      createdAt: _date(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'isAvailable': isAvailable,
    'rating': rating,
    'soldCount': soldCount,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  FoodModel copyWith({bool? isAvailable, int? soldCount, double? rating}) =>
      FoodModel(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        categoryId: categoryId,
        categoryName: categoryName,
        isAvailable: isAvailable ?? this.isAvailable,
        rating: rating ?? this.rating,
        soldCount: soldCount ?? this.soldCount,
        createdAt: createdAt,
      );
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return CategoryModel(
      id: _string(data['id']).isEmpty ? doc.id : _string(data['id']),
      name: _string(data['name']),
      icon: _string(data['icon']),
      color: _string(data['color']),
      sortOrder: _int(data['sortOrder']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'sortOrder': sortOrder,
  };

  CategoryModel copyWith({
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) => CategoryModel(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}

class CartItemModel {
  const CartItemModel({
    required this.foodId,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.quantity,
    this.note = '',
    this.selectedToppings = const [],
    this.toppingTotal = 0,
    this.itemTotal = 0,
  });

  final String foodId;
  final String name;
  final String imageUrl;
  final int basePrice;
  final int quantity;
  final String note;
  final List<ToppingModel> selectedToppings;
  final int toppingTotal;
  final int itemTotal;
  int get unitPrice => basePrice + toppingTotal;
  int get total => itemTotal > 0 ? itemTotal : unitPrice * quantity;
  String get uniqueKey {
    final toppingIds = selectedToppings.map((item) => item.id).toList()..sort();
    return '$foodId|$note|${toppingIds.join(',')}';
  }

  factory CartItemModel.fromMap(Map<String, dynamic> data) => CartItemModel(
    foodId: _string(data['foodId']),
    name: _string(data['name']),
    imageUrl: _string(data['imageUrl']),
    basePrice: data.containsKey('basePrice')
        ? _int(data['basePrice'])
        : _int(data['price']),
    quantity: _int(data['quantity']).clamp(1, 999).toInt(),
    note: _string(data['note']),
    selectedToppings: _maps(
      data['selectedToppings'],
    ).map(ToppingModel.fromMap).toList(growable: false),
    toppingTotal: _int(data['toppingTotal']),
    itemTotal: _int(data['itemTotal']),
  );

  Map<String, dynamic> toFirestore() => {
    'foodId': foodId,
    'foodName': name,
    'name': name,
    'imageUrl': imageUrl,
    'basePrice': basePrice,
    'price': basePrice,
    'quantity': quantity,
    'note': note,
    'selectedToppings': selectedToppings.map((item) => item.toMap()).toList(),
    'toppingTotal': toppingTotal,
    'itemTotal': total,
  };

  CartItemModel copyWith({
    int? quantity,
    String? note,
    List<ToppingModel>? selectedToppings,
    int? toppingTotal,
    int? itemTotal,
  }) => CartItemModel(
    foodId: foodId,
    name: name,
    imageUrl: imageUrl,
    basePrice: basePrice,
    quantity: quantity ?? this.quantity,
    note: note ?? this.note,
    selectedToppings: selectedToppings ?? this.selectedToppings,
    toppingTotal: toppingTotal ?? this.toppingTotal,
    itemTotal: itemTotal ?? this.itemTotal,
  );
}

class CartModel {
  const CartModel({
    required this.userId,
    required this.items,
    required this.updatedAt,
    this.voucherId,
    this.voucherCode,
    this.voucherDiscount = 0,
    this.deliveryFee = 2000,
  });

  final String userId;
  final List<CartItemModel> items;
  final DateTime updatedAt;
  final String? voucherId;
  final String? voucherCode;
  final int voucherDiscount;
  final int deliveryFee;

  int get subtotal => items.fold(0, (total, item) => total + item.total);
  int get totalAmount => items.isEmpty
      ? 0
      : (subtotal + deliveryFee - voucherDiscount).clamp(0, 1 << 31).toInt();

  factory CartModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return CartModel(
      userId: _string(data['userId']).isEmpty
          ? doc.id
          : _string(data['userId']),
      items: _maps(
        data['items'],
      ).map(CartItemModel.fromMap).toList(growable: false),
      updatedAt: _date(data['updatedAt']),
      voucherId: _string(data['voucherId']).isEmpty
          ? null
          : _string(data['voucherId']),
      voucherCode: _string(data['voucherCode']).isEmpty
          ? null
          : _string(data['voucherCode']),
      voucherDiscount: _int(data['voucherDiscount']),
      deliveryFee: data.containsKey('deliveryFee')
          ? _int(data['deliveryFee'])
          : 2000,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'items': items.map((item) => item.toFirestore()).toList(growable: false),
    'subtotal': subtotal,
    'voucherId': voucherId,
    'voucherCode': voucherCode,
    'voucherDiscount': voucherDiscount,
    'deliveryFee': deliveryFee,
    'totalAmount': totalAmount,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  CartModel copyWith({
    List<CartItemModel>? items,
    DateTime? updatedAt,
    String? voucherId,
    String? voucherCode,
    int? voucherDiscount,
    int? deliveryFee,
    bool clearVoucher = false,
  }) => CartModel(
    userId: userId,
    items: items ?? this.items,
    updatedAt: updatedAt ?? this.updatedAt,
    voucherId: clearVoucher ? null : (voucherId ?? this.voucherId),
    voucherCode: clearVoucher ? null : (voucherCode ?? this.voucherCode),
    voucherDiscount: clearVoucher
        ? 0
        : (voucherDiscount ?? this.voucherDiscount),
    deliveryFee: deliveryFee ?? this.deliveryFee,
  );
}

class OrderItemModel {
  const OrderItemModel({
    required this.foodId,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.quantity,
    this.note = '',
    this.selectedToppings = const [],
    this.toppingTotal = 0,
    this.itemTotal = 0,
  });

  final String foodId;
  final String name;
  final String imageUrl;
  final int basePrice;
  final int quantity;
  final String note;
  final List<ToppingModel> selectedToppings;
  final int toppingTotal;
  final int itemTotal;
  int get unitPrice => basePrice + toppingTotal;
  int get total => itemTotal > 0 ? itemTotal : unitPrice * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> data) => OrderItemModel(
    foodId: _string(data['foodId']),
    name: _string(data['name']),
    imageUrl: _string(data['imageUrl']),
    basePrice: data.containsKey('basePrice')
        ? _int(data['basePrice'])
        : _int(data['price']),
    quantity: _int(data['quantity']).clamp(1, 999).toInt(),
    note: _string(data['note']),
    selectedToppings: _maps(
      data['selectedToppings'],
    ).map(ToppingModel.fromMap).toList(growable: false),
    toppingTotal: _int(data['toppingTotal']),
    itemTotal: _int(data['itemTotal']),
  );

  Map<String, dynamic> toFirestore() => {
    'foodId': foodId,
    'name': name,
    'imageUrl': imageUrl,
    'basePrice': basePrice,
    'price': basePrice,
    'quantity': quantity,
    'note': note,
    'selectedToppings': selectedToppings.map((item) => item.toMap()).toList(),
    'toppingTotal': toppingTotal,
    'itemTotal': total,
  };
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.orderCode,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.pickupCounter,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.pickupEnabled,
    this.qrCodeData = '',
    this.pickupToken = '',
    this.hasReview = false,
    this.reviewId,
    this.reviewedAt,
  });

  final String id;
  final String userId;
  final String orderCode;
  final List<OrderItemModel> items;
  final int totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String pickupCounter;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pickupEnabled;
  final String qrCodeData;
  final String pickupToken;
  final bool hasReview;
  final String? reviewId;
  final DateTime? reviewedAt;

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return OrderModel(
      id: _string(data['id']).isEmpty ? doc.id : _string(data['id']),
      userId: _string(data['userId']),
      orderCode: _string(data['orderCode']),
      items: _maps(
        data['items'],
      ).map(OrderItemModel.fromMap).toList(growable: false),
      totalAmount: _int(data['totalAmount']),
      paymentMethod: _string(data['paymentMethod']),
      paymentStatus: _string(data['paymentStatus']),
      orderStatus: _string(data['orderStatus']),
      pickupCounter: _string(data['pickupCounter']),
      note: _string(data['note']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      pickupEnabled: _bool(data['pickupEnabled'], true),
      qrCodeData: _string(data['qrCodeData']),
      pickupToken: _string(data['pickupToken']),
      hasReview: _bool(data['hasReview'], false),
      reviewId: data['reviewId'] != null ? _string(data['reviewId']) : null,
      reviewedAt: data['reviewedAt'] != null ? _date(data['reviewedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'orderCode': orderCode,
    'items': items.map((item) => item.toFirestore()).toList(growable: false),
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'orderStatus': orderStatus,
    'pickupCounter': pickupCounter,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'pickupEnabled': pickupEnabled,
    'qrCodeData': qrCodeData,
    'pickupToken': pickupToken,
    'hasReview': hasReview,
    'reviewId': reviewId,
    'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
  };

  OrderModel copyWith({
    String? paymentStatus,
    String? orderStatus,
    DateTime? updatedAt,
    String? qrCodeData,
    String? pickupToken,
    bool? pickupEnabled,
    bool? hasReview,
    String? reviewId,
    DateTime? reviewedAt,
  }) => OrderModel(
    id: id,
    userId: userId,
    orderCode: orderCode,
    items: items,
    totalAmount: totalAmount,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    orderStatus: orderStatus ?? this.orderStatus,
    pickupCounter: pickupCounter,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pickupEnabled: pickupEnabled ?? this.pickupEnabled,
    qrCodeData: qrCodeData ?? this.qrCodeData,
    pickupToken: pickupToken ?? this.pickupToken,
    hasReview: hasReview ?? this.hasReview,
    reviewId: reviewId ?? this.reviewId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
  );
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceId = '',
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String referenceId;

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return NotificationModel(
      id: _string(data['id']).isEmpty ? doc.id : _string(data['id']),
      userId: _string(data['userId']),
      title: _string(data['title']),
      message: _string(data['message']),
      type: _string(data['type']),
      isRead: _bool(data['isRead']),
      createdAt: _date(data['createdAt']),
      referenceId: _string(data['referenceId']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'referenceId': referenceId,
  };

  NotificationModel copyWith({bool? isRead, String? referenceId}) => NotificationModel(
    id: id,
    userId: userId,
    title: title,
    message: message,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    referenceId: referenceId ?? this.referenceId,
  );
}

class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscount,
    required this.usageLimit,
    required this.usedCount,
    required this.claimLimit,
    required this.claimedCount,
    required this.userLimit,
    required this.exchangePoints,
    required this.isExchangeable,
    required this.isClaimable,
    required this.isActive,
    this.startedAt,
    required this.expiredAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String code;
  final String description;
  final String discountType;
  final int discountValue;
  final int minOrderAmount;
  final int maxDiscount;
  final int usageLimit;
  final int usedCount;
  final int claimLimit;
  final int claimedCount;
  final int userLimit;
  final int exchangePoints;
  final bool isExchangeable;
  final bool isClaimable;
  final bool isActive;
  final DateTime? startedAt;
  final DateTime expiredAt;
  final DateTime? createdAt;

  factory VoucherModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return VoucherModel(
      id: (data['id'] ?? doc.id).toString(),
      title: (data['title'] ?? 'Ưu đãi').toString(),
      code: (data['code'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      discountType: (data['discountType'] ?? '').toString(),
      discountValue: _int(data['discountValue']),
      minOrderAmount: _int(data['minOrderAmount']),
      maxDiscount: _int(data['maxDiscount'] ?? data['maxDiscountAmount']),
      usageLimit: _int(data['usageLimit']),
      usedCount: _int(data['usedCount']),
      claimLimit: _int(data['claimLimit'] ?? 999999),
      claimedCount: _int(data['claimedCount']),
      userLimit: _int(data['userLimit'] ?? 1),
      exchangePoints: _int(data['exchangePoints']),
      isExchangeable: _bool(data['isExchangeable'], false),
      isClaimable: _bool(data['isClaimable'], true),
      isActive: _bool(data['isActive'], true),
      startedAt: data.containsKey('startedAt') && data['startedAt'] != null
          ? _date(data['startedAt'])
          : null,
      expiredAt: _date(data['expiredAt']),
      createdAt: data.containsKey('createdAt') && data['createdAt'] != null
          ? _date(data['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'title': title,
    'code': code,
    'description': description,
    'discountType': discountType,
    'discountValue': discountValue,
    'minOrderAmount': minOrderAmount,
    'maxDiscount': maxDiscount,
    'usageLimit': usageLimit,
    'usedCount': usedCount,
    'claimLimit': claimLimit,
    'claimedCount': claimedCount,
    'userLimit': userLimit,
    'exchangePoints': exchangePoints,
    'isExchangeable': isExchangeable,
    'isClaimable': isClaimable,
    'isActive': isActive,
    if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
    'expiredAt': Timestamp.fromDate(expiredAt),
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };

  VoucherModel copyWith({
    bool? isActive,
    int? claimedCount,
    int? usedCount,
  }) => VoucherModel(
    id: id,
    title: title,
    code: code,
    description: description,
    discountType: discountType,
    discountValue: discountValue,
    minOrderAmount: minOrderAmount,
    maxDiscount: maxDiscount,
    usageLimit: usageLimit,
    usedCount: usedCount ?? this.usedCount,
    claimLimit: claimLimit,
    claimedCount: claimedCount ?? this.claimedCount,
    userLimit: userLimit,
    exchangePoints: exchangePoints,
    isExchangeable: isExchangeable,
    isClaimable: isClaimable,
    isActive: isActive ?? this.isActive,
    startedAt: startedAt,
    expiredAt: expiredAt,
    createdAt: createdAt,
  );
}

class UserVoucherModel {
  const UserVoucherModel({
    required this.id,
    required this.userId,
    required this.voucherId,
    required this.voucherCode,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscount,
    required this.source,
    required this.status,
    required this.claimedAt,
    required this.expiredAt,
    this.usedAt,
    this.orderId,
  });

  final String id;
  final String userId;
  final String voucherId;
  final String voucherCode;
  final String title;
  final String description;
  final String discountType;
  final int discountValue;
  final int minOrderAmount;
  final int maxDiscount;
  final String source;
  final String status;
  final DateTime claimedAt;
  final DateTime expiredAt;
  final DateTime? usedAt;
  final String? orderId;

  factory UserVoucherModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final title = (data['title'] ?? '').toString();
    final voucherId = (data['voucherId'] ?? data['id'] ?? '').toString();
    final voucherCode = (data['voucherCode'] ?? data['code'] ?? '').toString();
    final status = (data['status'] ?? 'available').toString();
    final source = (data['source'] ?? 'claim').toString();
    return UserVoucherModel(
      id: (data['id'] ?? doc.id).toString(),
      userId: (data['userId'] ?? '').toString(),
      voucherId: voucherId,
      voucherCode: voucherCode,
      title: title,
      description: (data['description'] ?? '').toString(),
      discountType: (data['discountType'] ?? '').toString(),
      discountValue: _int(data['discountValue']),
      minOrderAmount: _int(data['minOrderAmount']),
      maxDiscount: _int(data['maxDiscount'] ?? data['maxDiscountAmount']),
      source: source,
      status: status,
      claimedAt: _date(data['claimedAt']),
      expiredAt: _date(data['expiredAt']),
      usedAt: data['usedAt'] == null ? null : _date(data['usedAt']),
      orderId: data['orderId']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'voucherId': voucherId,
    'voucherCode': voucherCode,
    'title': title,
    'description': description,
    'discountType': discountType,
    'discountValue': discountValue,
    'minOrderAmount': minOrderAmount,
    'maxDiscount': maxDiscount,
    'source': source,
    'status': status,
    'claimedAt': Timestamp.fromDate(claimedAt),
    'expiredAt': Timestamp.fromDate(expiredAt),
    if (usedAt != null) 'usedAt': Timestamp.fromDate(usedAt!),
    if (orderId != null) 'orderId': orderId,
  };
}

class VoucherUsageModel {
  const VoucherUsageModel({
    required this.id,
    required this.userId,
    required this.voucherId,
    required this.userVoucherId,
    required this.voucherCode,
    required this.orderId,
    required this.discountAmount,
    required this.usedAt,
  });

  final String id;
  final String userId;
  final String voucherId;
  final String userVoucherId;
  final String voucherCode;
  final String orderId;
  final int discountAmount;
  final DateTime usedAt;

  factory VoucherUsageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return VoucherUsageModel(
      id: _string(data['id']).isEmpty ? doc.id : _string(data['id']),
      userId: _string(data['userId']),
      voucherId: _string(data['voucherId']),
      userVoucherId: _string(data['userVoucherId']),
      voucherCode: _string(data['voucherCode']),
      orderId: _string(data['orderId']),
      discountAmount: _int(data['discountAmount']),
      usedAt: _date(data['usedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'voucherId': voucherId,
    'userVoucherId': userVoucherId,
    'voucherCode': voucherCode,
    'orderId': orderId,
    'discountAmount': discountAmount,
    'usedAt': Timestamp.fromDate(usedAt),
  };
}

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.createdAt,
    this.orderCode = '',
    this.foodIds = const [],
    this.serviceRatings = const {},
    this.imageUrls = const [],
  });

  final String id;
  final String userId;
  final String orderId;
  final int rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;
  final String orderCode;
  final List<String> foodIds;
  final Map<String, int> serviceRatings;
  final List<String> imageUrls;

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final rawServiceRatings = data['serviceRatings'] as Map?;
    final Map<String, int> mappedServiceRatings = {};
    if (rawServiceRatings != null) {
      rawServiceRatings.forEach((k, v) {
        mappedServiceRatings[k.toString()] = _int(v).toInt();
      });
    }
    return ReviewModel(
      id: _string(data['id']).isEmpty ? doc.id : _string(data['id']),
      userId: _string(data['userId']),
      orderId: _string(data['orderId']),
      rating: _int(data['rating']).clamp(1, 5).toInt(),
      comment: _string(data['comment']),
      tags:
          (data['tags'] as List?)
              ?.map(_string)
              .where((item) => item.isNotEmpty)
              .toList() ??
          const [],
      createdAt: _date(data['createdAt']),
      orderCode: _string(data['orderCode']),
      foodIds: (data['foodIds'] as List?)?.map(_string).toList() ?? const [],
      serviceRatings: mappedServiceRatings,
      imageUrls: (data['imageUrls'] as List?)?.map(_string).toList() ?? const [],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'orderId': orderId,
    'rating': rating,
    'comment': comment,
    'tags': tags,
    'createdAt': Timestamp.fromDate(createdAt),
    'orderCode': orderCode,
    'foodIds': foodIds,
    'serviceRatings': serviceRatings,
    'imageUrls': imageUrls,
  };

  ReviewModel copyWith({
    int? rating,
    String? comment,
    List<String>? tags,
    String? orderCode,
    List<String>? foodIds,
    Map<String, int>? serviceRatings,
    List<String>? imageUrls,
  }) =>
      ReviewModel(
        id: id,
        userId: userId,
        orderId: orderId,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        orderCode: orderCode ?? this.orderCode,
        foodIds: foodIds ?? this.foodIds,
        serviceRatings: serviceRatings ?? this.serviceRatings,
        imageUrls: imageUrls ?? this.imageUrls,
      );
}
