import 'package:cloud_firestore/cloud_firestore.dart';

String _string(dynamic value) => value?.toString() ?? '';

class PaymentSettingsModel {
  const PaymentSettingsModel({
    required this.bankId,
    required this.bankName,
    required this.bankAccountNo,
    required this.bankAccountName,
    required this.qrAccountName,
    required this.qrTemplate,
  });

  static const fallback = PaymentSettingsModel(
    bankId: 'MB',
    bankName: 'MB BANK',
    bankAccountNo: '195989',
    bankAccountName: 'Nguyễn Hải Nam',
    qrAccountName: 'NguyenHaiNam',
    qrTemplate: 'compact2',
  );

  factory PaymentSettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PaymentSettingsModel(
      bankId: _value(data['bankId'], fallback.bankId),
      bankName: _value(data['bankName'], fallback.bankName),
      bankAccountNo: _value(data['bankAccountNo'], fallback.bankAccountNo),
      bankAccountName: _value(
        data['bankAccountName'],
        fallback.bankAccountName,
      ),
      qrAccountName: _value(data['qrAccountName'], fallback.qrAccountName),
      qrTemplate: _value(data['qrTemplate'], fallback.qrTemplate),
    );
  }

  final String bankId;
  final String bankName;
  final String bankAccountNo;
  final String bankAccountName;
  final String qrAccountName;
  final String qrTemplate;

  Map<String, dynamic> toFirestore() => {
    'bankId': bankId,
    'bankName': bankName,
    'bankAccountNo': bankAccountNo,
    'bankAccountName': bankAccountName,
    'qrAccountName': qrAccountName,
    'qrTemplate': qrTemplate,
  };

  static String _value(dynamic value, String fallback) {
    final text = _string(value).trim();
    return text.isEmpty ? fallback : text;
  }
}
