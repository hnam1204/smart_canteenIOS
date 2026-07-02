import 'package:cloud_firestore/cloud_firestore.dart';

String _string(dynamic value) => value?.toString() ?? '';

int _int(dynamic value) {
  if (value is num) {
    final doubleValue = value.toDouble();
    if (!doubleValue.isFinite) return 0;
    return value.toInt();
  }
  if (value is String) {
    return _int(num.tryParse(value.trim()));
  }
  return 0;
}

String _imageString(Map<String, dynamic> data) {
  const keys = [
    'imageUrl',
    'image',
    'photoUrl',
    'thumbnail',
    'thumbnailUrl',
    'image_url',
    'photo_url',
  ];
  for (final key in keys) {
    final value = _string(data[key]).trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final String buttonText;
  final String actionType; // menu | voucher | food | url
  final String actionValue;
  final String discountText;
  final int sortOrder;
  final bool isActive;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.buttonText,
    required this.actionType,
    required this.actionValue,
    required this.discountText,
    required this.sortOrder,
    required this.isActive,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return BannerModel(
      id: data['id']?.toString() ?? doc.id,
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: _imageString(data),
      buttonText: data['buttonText']?.toString() ?? '',
      actionType: data['actionType']?.toString() ?? 'menu',
      actionValue: data['actionValue']?.toString() ?? '',
      discountText: data['discountText']?.toString() ?? '',
      sortOrder: _int(data['sortOrder']),
      isActive: data['isActive'] == true,
      startAt: parseDate(data['startAt']),
      endAt: parseDate(data['endAt']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'buttonText': buttonText,
      'actionType': actionType,
      'actionValue': actionValue,
      'discountText': discountText,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
