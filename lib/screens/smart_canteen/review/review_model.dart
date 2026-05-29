import 'package:flutter/material.dart';

class ReviewOrderItemModel {
  const ReviewOrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageAsset,
  });

  final String name;
  final int quantity;
  final int price;
  final String imageAsset;

  int get total => quantity * price;
}

class ReviewOrderModel {
  const ReviewOrderModel({
    required this.id,
    required this.orderedAt,
    required this.items,
  });

  final String id;
  final String orderedAt;
  final List<ReviewOrderItemModel> items;

  int get total => items.fold<int>(0, (sum, item) => sum + item.total);
}

class ReviewTagModel {
  const ReviewTagModel({required this.id, required this.label});

  final String id;
  final String label;
}

class ServiceRatingModel {
  const ServiceRatingModel({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class ReviewImageModel {
  const ReviewImageModel({
    required this.id,
    required this.icon,
    required this.colors,
  });

  final String id;
  final IconData icon;
  final List<Color> colors;
}

class ReviewModel {
  const ReviewModel({
    required this.orderId,
    required this.rating,
    required this.tags,
    required this.comment,
    required this.serviceRatings,
    required this.imageCount,
    required this.createdAt,
    required this.canEdit,
  });

  final String orderId;
  final int rating;
  final Set<String> tags;
  final String comment;
  final Map<String, int> serviceRatings;
  final int imageCount;
  final String createdAt;
  final bool canEdit;
}

const demoReviewOrder = ReviewOrderModel(
  id: 'SC250522-000123',
  orderedAt: '22/05/2026 - 09:30',
  items: [
    ReviewOrderItemModel(
      name: 'Cơm gà xối mỡ',
      quantity: 1,
      price: 32000,
      imageAsset: 'assets/images/chicken_rice.jpg',
    ),
    ReviewOrderItemModel(
      name: 'Trà tắc',
      quantity: 1,
      price: 12000,
      imageAsset: 'assets/images/pho.jpg',
    ),
    ReviewOrderItemModel(
      name: 'Bánh flan',
      quantity: 1,
      price: 10000,
      imageAsset: 'assets/images/salad.jpg',
    ),
  ],
);

const demoReviewTags = <ReviewTagModel>[
  ReviewTagModel(id: 'delicious', label: 'Món ngon'),
  ReviewTagModel(id: 'fast', label: 'Giao nhanh'),
  ReviewTagModel(id: 'package', label: 'Đóng gói đẹp'),
  ReviewTagModel(id: 'value', label: 'Giá hợp lý'),
  ReviewTagModel(id: 'friendly', label: 'Nhân viên thân thiện'),
  ReviewTagModel(id: 'rebuy', label: 'Sẽ mua lại'),
];

const demoServiceRatings = <ServiceRatingModel>[
  ServiceRatingModel(
    id: 'food',
    label: 'Chất lượng món ăn',
    icon: Icons.restaurant_rounded,
  ),
  ServiceRatingModel(
    id: 'speed',
    label: 'Tốc độ chuẩn bị',
    icon: Icons.timer_outlined,
  ),
  ServiceRatingModel(
    id: 'service',
    label: 'Thái độ phục vụ',
    icon: Icons.sentiment_satisfied_alt_rounded,
  ),
];

const demoReviewImages = <ReviewImageModel>[
  ReviewImageModel(
    id: 'review-image-1',
    icon: Icons.ramen_dining_rounded,
    colors: [Color(0xFFFFE4CF), Color(0xFFFFF5EB)],
  ),
  ReviewImageModel(
    id: 'review-image-2',
    icon: Icons.local_drink_outlined,
    colors: [Color(0xFFFFEBC9), Color(0xFFFFFAED)],
  ),
  ReviewImageModel(
    id: 'review-image-3',
    icon: Icons.cake_outlined,
    colors: [Color(0xFFFFE3DE), Color(0xFFFFF4F1)],
  ),
];

const demoReviewHistory = <ReviewModel>[
  ReviewModel(
    orderId: 'SC250518-000019',
    rating: 5,
    tags: {'delicious', 'rebuy'},
    comment: 'Món ăn nóng, phục vụ nhanh và rất vừa vị.',
    serviceRatings: {'food': 5, 'speed': 5, 'service': 5},
    imageCount: 1,
    createdAt: '18/05/2026 - 12:04',
    canEdit: false,
  ),
  ReviewModel(
    orderId: 'SC250520-000045',
    rating: 4,
    tags: {'fast', 'friendly'},
    comment: 'Đóng gói gọn, thời gian chuẩn bị hợp lý.',
    serviceRatings: {'food': 4, 'speed': 5, 'service': 4},
    imageCount: 0,
    createdAt: '20/05/2026 - 09:20',
    canEdit: true,
  ),
];
