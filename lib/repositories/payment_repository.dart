import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_service.dart';

class PaymentRepository {
  PaymentRepository({FirestoreService? service})
    : _service = service ?? FirestoreService();

  final FirestoreService _service;

  Future<void> createPendingBankPayment({
    required String id,
    required String orderId,
    required String userId,
    required int amount,
    required String description,
  }) => _service.set(_service.collection('payments').doc(id), {
    'id': id,
    'orderId': orderId,
    'userId': userId,
    'amount': amount,
    'method': 'bankQr',
    'status': 'pending',
    'description': description,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
