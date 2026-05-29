import 'package:flutter/material.dart';

enum HelpCategory {
  all,
  ordering,
  payment,
  reward,
  voucher,
  account,
  order,
  delivery,
  security,
}

enum QuickSupportAction {
  contact,
  hotline,
  liveChat,
  reportIssue,
  trackOrder,
  refundPolicy,
}

enum ProblemType { order, payment, application, account, other }

enum SupportStatus { processing, replied, closed }

class HelpActionModel {
  const HelpActionModel({
    required this.action,
    required this.title,
    required this.icon,
    required this.color,
  });

  final QuickSupportAction action;
  final String title;
  final IconData icon;
  final Color color;
}

class FAQModel {
  const FAQModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  final String id;
  final HelpCategory category;
  final String question;
  final String answer;
}

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.reply,
    this.hasAttachment = false,
  });

  final String id;
  final ProblemType type;
  final String title;
  final String description;
  final SupportStatus status;
  final String submittedAt;
  final String? reply;
  final bool hasAttachment;

  SupportTicketModel copyWith({SupportStatus? status, String? reply}) {
    return SupportTicketModel(
      id: id,
      type: type,
      title: title,
      description: description,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reply: reply ?? this.reply,
      hasAttachment: hasAttachment,
    );
  }
}

String helpCategoryLabel(HelpCategory category) => switch (category) {
  HelpCategory.all => 'Tất cả',
  HelpCategory.ordering => 'Đặt món',
  HelpCategory.payment => 'Thanh toán',
  HelpCategory.reward => 'Điểm thưởng',
  HelpCategory.voucher => 'Voucher',
  HelpCategory.account => 'Tài khoản',
  HelpCategory.order => 'Đơn hàng',
  HelpCategory.delivery => 'Giao hàng',
  HelpCategory.security => 'Bảo mật',
};

String problemTypeLabel(ProblemType type) => switch (type) {
  ProblemType.order => 'Đơn hàng',
  ProblemType.payment => 'Thanh toán',
  ProblemType.application => 'App lỗi',
  ProblemType.account => 'Tài khoản',
  ProblemType.other => 'Khác',
};

String supportStatusLabel(SupportStatus status) => switch (status) {
  SupportStatus.processing => 'Đang xử lý',
  SupportStatus.replied => 'Đã phản hồi',
  SupportStatus.closed => 'Đã đóng',
};

const quickSupportActions = [
  HelpActionModel(
    action: QuickSupportAction.contact,
    title: 'Liên hệ hỗ trợ',
    icon: Icons.support_agent_rounded,
    color: Color(0xFFFF6B00),
  ),
  HelpActionModel(
    action: QuickSupportAction.hotline,
    title: 'Gọi hotline',
    icon: Icons.call_outlined,
    color: Color(0xFF16A34A),
  ),
  HelpActionModel(
    action: QuickSupportAction.liveChat,
    title: 'Chat trực tuyến',
    icon: Icons.chat_bubble_outline_rounded,
    color: Color(0xFF2563EB),
  ),
  HelpActionModel(
    action: QuickSupportAction.reportIssue,
    title: 'Báo lỗi ứng dụng',
    icon: Icons.bug_report_outlined,
    color: Color(0xFFDC2626),
  ),
  HelpActionModel(
    action: QuickSupportAction.trackOrder,
    title: 'Theo dõi đơn',
    icon: Icons.location_searching_rounded,
    color: Color(0xFFF59E0B),
  ),
  HelpActionModel(
    action: QuickSupportAction.refundPolicy,
    title: 'Chính sách hoàn tiền',
    icon: Icons.policy_outlined,
    color: Color(0xFF7C3AED),
  ),
];

const demoFaqs = [
  FAQModel(
    id: 'faq_order',
    category: HelpCategory.ordering,
    question: 'Làm sao để đặt món?',
    answer:
        'Chọn món trong Menu, thêm vào giỏ hàng, kiểm tra quầy nhận và hoàn tất thanh toán. Trạng thái đơn sẽ cập nhật theo thời gian thực.',
  ),
  FAQModel(
    id: 'faq_cancel',
    category: HelpCategory.order,
    question: 'Làm sao để hủy đơn?',
    answer:
        'Bạn có thể hủy đơn khi đơn còn ở trạng thái Chờ xác nhận. Khi bếp đã chuẩn bị món, vui lòng liên hệ hỗ trợ.',
  ),
  FAQModel(
    id: 'faq_reward',
    category: HelpCategory.reward,
    question: 'Điểm thưởng dùng như thế nào?',
    answer:
        'Điểm được cộng sau đơn hợp lệ và có thể đổi voucher, freeship hoặc món miễn phí tại trang Điểm thưởng.',
  ),
  FAQModel(
    id: 'faq_payment',
    category: HelpCategory.payment,
    question: 'Vì sao thanh toán thất bại?',
    answer:
        'Kiểm tra kết nối, số dư và phương thức thanh toán. Nếu tiền đã trừ nhưng đơn chưa tạo, gửi ticket để được xử lý.',
  ),
  FAQModel(
    id: 'faq_password',
    category: HelpCategory.security,
    question: 'Làm sao đổi mật khẩu?',
    answer:
        'Vào Tài khoản > Thông tin cá nhân > Bảo mật tài khoản để đổi mật khẩu và kiểm tra phiên đăng nhập.',
  ),
  FAQModel(
    id: 'faq_contact',
    category: HelpCategory.account,
    question: 'Làm sao liên hệ hỗ trợ?',
    answer:
        'Bạn có thể chat trực tuyến, gọi hotline 1900 123 456 hoặc gửi mô tả vấn đề trong biểu mẫu hỗ trợ.',
  ),
  FAQModel(
    id: 'faq_voucher',
    category: HelpCategory.voucher,
    question: 'Voucher có thể dùng cùng điểm thưởng không?',
    answer:
        'Một số voucher có thể kết hợp điểm thưởng. Điều kiện chi tiết được hiển thị trước khi thanh toán.',
  ),
  FAQModel(
    id: 'faq_delivery',
    category: HelpCategory.delivery,
    question: 'Theo dõi giao món ở đâu?',
    answer:
        'Các đơn đang giao hiển thị thời gian dự kiến và thông tin nhân viên giao trong phần Tất cả đơn hàng.',
  ),
];

const demoSupportTickets = [
  SupportTicketModel(
    id: 'SPT-250524-009',
    type: ProblemType.payment,
    title: 'Thanh toán bị trừ tiền hai lần',
    description: 'Tôi cần kiểm tra giao dịch thanh toán của đơn hàng.',
    status: SupportStatus.replied,
    submittedAt: '24/05/2026, 18:30',
    reply:
        'Đã kiểm tra giao dịch. Khoản thanh toán dư sẽ được hoàn trong 1-3 ngày làm việc.',
  ),
  SupportTicketModel(
    id: 'SPT-250521-004',
    type: ProblemType.order,
    title: 'Thiếu món trong đơn hàng',
    description: 'Đơn của tôi thiếu một phần nước uống.',
    status: SupportStatus.closed,
    submittedAt: '21/05/2026, 12:40',
    reply: 'Voucher bồi hoàn 20.000đ đã được gửi vào tài khoản.',
    hasAttachment: true,
  ),
];
