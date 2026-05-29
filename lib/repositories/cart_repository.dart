import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_service.dart';
import '../models/firestore_models.dart';

class CartRepository {
  CartRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Stream<CartModel?> watchCart(String userId) => _service.streamDocument(
    document: _service.collection('carts').doc(userId),
    fromFirestore: CartModel.fromFirestore,
  );

  Future<void> saveCart(CartModel cart) => _service.set(
    _service.collection('carts').doc(cart.userId),
    cart.copyWith(updatedAt: DateTime.now()).toFirestore(),
  );

  Future<void> clear(String userId) =>
      _service.update(_service.collection('carts').doc(userId), {
        'items': <Map<String, dynamic>>[],
        'subtotal': 0,
        'voucherId': null,
        'voucherCode': null,
        'voucherDiscount': 0,
        'deliveryFee': 2000,
        'totalAmount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
