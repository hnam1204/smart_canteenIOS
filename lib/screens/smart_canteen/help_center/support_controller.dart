import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/support_ticket_model.dart';
import '../../../models/support_message_model.dart';
import '../../../repositories/support_repository.dart';
import '../../../repositories/user_repository.dart';

class SupportController extends ChangeNotifier {
  SupportController({SupportRepository? repository})
      : _repository = repository ?? SupportRepository();

  final SupportRepository _repository;
  
  List<SupportTicketModel> _tickets = [];
  List<SupportTicketModel> get tickets => _tickets;

  List<SupportMessageModel> _messages = [];
  List<SupportMessageModel> get messages => _messages;

  SupportTicketModel? _activeTicket;
  SupportTicketModel? get activeTicket => _activeTicket;

  bool _loadingTickets = false;
  bool get loadingTickets => _loadingTickets;

  bool _submittingTicket = false;
  bool get submittingTicket => _submittingTicket;

  bool _loadingMessages = false;
  bool get loadingMessages => _loadingMessages;

  bool _hasMessagesError = false;
  bool get hasMessagesError => _hasMessagesError;

  StreamSubscription<List<SupportTicketModel>>? _ticketsSubscription;
  StreamSubscription<List<SupportMessageModel>>? _messagesSubscription;
  StreamSubscription<SupportTicketModel?>? _activeTicketSubscription;

  // Fallback demo data for tests or when Firebase is not initialized
  static final List<SupportTicketModel> _demoTickets = [
    SupportTicketModel(
      id: 'SPT-250524-009',
      userId: 'demo-uid',
      fullName: 'Nguyễn Thảo Vy',
      email: 'thaovy.nguyen@gmail.com',
      phone: '0901 234 567',
      category: 'Thanh toán',
      title: 'Thanh toán bị trừ tiền hai lần',
      message: 'Tôi cần kiểm tra giao dịch thanh toán của đơn hàng.',
      imageUrls: [],
      status: 'replied',
      lastMessage: 'Đã kiểm tra giao dịch. Khoản thanh toán dư sẽ được hoàn trong 1-3 ngày làm việc.',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      unreadByUser: true,
      unreadByAdmin: false,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SupportTicketModel(
      id: 'SPT-250521-004',
      userId: 'demo-uid',
      fullName: 'Nguyễn Thảo Vy',
      email: 'thaovy.nguyen@gmail.com',
      phone: '0901 234 567',
      category: 'Đơn hàng',
      title: 'Thiếu món trong đơn hàng',
      message: 'Đơn của tôi thiếu một phần nước uống.',
      imageUrls: [],
      status: 'closed',
      lastMessage: 'Voucher bồi hoàn 20.000đ đã được gửi vào tài khoản.',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 3)),
      unreadByUser: false,
      unreadByAdmin: false,
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    )
  ];

  static final Map<String, List<SupportMessageModel>> _demoMessages = {
    'SPT-250524-009': [
      SupportMessageModel(
        id: 'msg1',
        ticketId: 'SPT-250524-009',
        senderId: 'demo-uid',
        senderName: 'Nguyễn Thảo Vy',
        senderRole: 'user',
        message: 'Tôi cần kiểm tra giao dịch thanh toán của đơn hàng.',
        imageUrls: [],
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      SupportMessageModel(
        id: 'msg2',
        ticketId: 'SPT-250524-009',
        senderId: 'admin-uid',
        senderName: 'Hỗ trợ viên',
        senderRole: 'admin',
        message: 'Đã kiểm tra giao dịch. Khoản thanh toán dư sẽ được hoàn trong 1-3 ngày làm việc.',
        imageUrls: [],
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
    'SPT-250521-004': [
      SupportMessageModel(
        id: 'msg3',
        ticketId: 'SPT-250521-004',
        senderId: 'demo-uid',
        senderName: 'Nguyễn Thảo Vy',
        senderRole: 'user',
        message: 'Đơn của tôi thiếu một phần nước uống.',
        imageUrls: [],
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SupportMessageModel(
        id: 'msg4',
        ticketId: 'SPT-250521-004',
        senderId: 'admin-uid',
        senderName: 'Hỗ trợ viên',
        senderRole: 'admin',
        message: 'Voucher bồi hoàn 20.000đ đã được gửi vào tài khoản.',
        imageUrls: [],
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]
  };

  void startWatchingTickets() {
    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;
    
    if (!hasFirebase || user == null) {
      // Mock mode
      _tickets = List.from(_demoTickets);
      _loadingTickets = false;
      notifyListeners();
      return;
    }

    _loadingTickets = true;
    notifyListeners();

    _ticketsSubscription?.cancel();
    _ticketsSubscription = _repository.watchUserTickets(user.uid).listen(
      (list) {
        _tickets = list;
        _loadingTickets = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading support tickets: $e');
        _loadingTickets = false;
        notifyListeners();
      },
    );
  }

  void stopWatchingTickets() {
    _ticketsSubscription?.cancel();
  }

  void startWatchingMessages(String ticketId) {
    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;

    _hasMessagesError = false;

    if (!hasFirebase || user == null) {
      // Mock mode
      _messages = List.from(_demoMessages[ticketId] ?? []);
      final idx = _demoTickets.indexWhere((t) => t.id == ticketId);
      _activeTicket = idx != -1 ? _demoTickets[idx] : null;
      _loadingMessages = false;
      notifyListeners();
      
      // Mark as read in mock mode
      if (idx != -1) {
        _demoTickets[idx] = _demoTickets[idx].copyWith(unreadByUser: false);
      }
      return;
    }

    _loadingMessages = true;
    notifyListeners();

    _activeTicketSubscription?.cancel();
    _activeTicketSubscription = _repository.watchTicket(ticketId).listen(
      (ticket) {
        _activeTicket = ticket;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading active ticket: $e');
      },
    );

    _messagesSubscription?.cancel();
    _messagesSubscription = _repository.watchTicketMessages(ticketId).listen(
      (list) {
        _messages = list;
        _loadingMessages = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading ticket messages: $e');
        _loadingMessages = false;
        _hasMessagesError = true;
        notifyListeners();
      },
    );

    // Also mark as read in Firestore
    markAsRead(ticketId);
  }

  void stopWatchingMessages() {
    _messagesSubscription?.cancel();
    _activeTicketSubscription?.cancel();
    _messages = [];
    _activeTicket = null;
  }

  Future<bool> createSupportTicket({
    required String category,
    required String title,
    required String message,
    List<String> imageUrls = const [],
  }) async {
    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;

    _submittingTicket = true;
    notifyListeners();

    if (!hasFirebase || user == null) {
      // Mock mode
      await Future.delayed(const Duration(milliseconds: 300));
      final ticketId = 'SPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final newTicket = SupportTicketModel(
        id: ticketId,
        userId: 'demo-uid',
        fullName: 'Nguyễn Thảo Vy',
        email: 'thaovy.nguyen@gmail.com',
        phone: '0901 234 567',
        category: category,
        title: title,
        message: message,
        imageUrls: imageUrls,
        status: 'pending',
        lastMessage: message,
        lastMessageAt: DateTime.now(),
        unreadByUser: false,
        unreadByAdmin: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _demoTickets.insert(0, newTicket);
      _demoMessages[ticketId] = [
        SupportMessageModel(
          id: 'mock-msg-${DateTime.now().millisecondsSinceEpoch}',
          ticketId: ticketId,
          senderId: 'demo-uid',
          senderName: 'Nguyễn Thảo Vy',
          senderRole: 'user',
          message: message,
          imageUrls: imageUrls,
          isRead: true,
          createdAt: DateTime.now(),
        )
      ];

      _tickets = List.from(_demoTickets);
      _submittingTicket = false;
      notifyListeners();
      return true;
    }

    try {
      final ticketId = 'ST-${DateTime.now().millisecondsSinceEpoch}';
      
      // Fetch user profile info
      final profile = await UserRepository().getUser(user.uid);
      final fullName = profile?.fullName ?? user.displayName ?? 'Người dùng';
      final email = profile?.email ?? user.email ?? '';
      final phone = profile?.phone ?? user.phoneNumber ?? '';

      final ticket = SupportTicketModel(
        id: ticketId,
        userId: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        category: category,
        title: title,
        message: message,
        imageUrls: imageUrls,
        status: 'pending',
        lastMessage: message,
        lastMessageAt: DateTime.now(),
        unreadByUser: false,
        unreadByAdmin: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createTicket(ticket, message);
      _submittingTicket = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      _submittingTicket = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendChatMessage(String ticketId, String messageText, {List<String> imageUrls = const []}) async {
    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;

    if (!hasFirebase || user == null) {
      // Mock mode
      final msgId = 'mock-msg-${DateTime.now().millisecondsSinceEpoch}';
      final message = SupportMessageModel(
        id: msgId,
        ticketId: ticketId,
        senderId: 'demo-uid',
        senderName: 'Nguyễn Thảo Vy',
        senderRole: 'user',
        message: messageText,
        imageUrls: imageUrls,
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      if (!_demoMessages.containsKey(ticketId)) {
        _demoMessages[ticketId] = [];
      }
      _demoMessages[ticketId]!.add(message);
      _messages = List.from(_demoMessages[ticketId]!);
      
      final idx = _demoTickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        final ticket = _demoTickets[idx];
        if (ticket.status == 'closed') {
          return false;
        }
        _demoTickets[idx] = ticket.copyWith(
          lastMessage: messageText,
          lastMessageAt: message.createdAt,
          unreadByAdmin: true,
          updatedAt: message.createdAt,
          status: ticket.status == 'replied' ? 'pending' : ticket.status,
        );
      }
      _tickets = List.from(_demoTickets);
      notifyListeners();
      return true;
    }

    try {
      final profile = await UserRepository().getUser(user.uid);
      final senderName = profile?.fullName ?? user.displayName ?? 'Người dùng';
      await _repository.sendMessage(
        ticketId: ticketId,
        senderId: user.uid,
        senderName: senderName,
        messageText: messageText,
        imageUrls: imageUrls,
      );
      return true;
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      return false;
    }
  }

  Future<void> markAsRead(String ticketId) async {
    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;
    
    if (!hasFirebase || user == null) {
      final idx = _demoTickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _demoTickets[idx] = _demoTickets[idx].copyWith(unreadByUser: false);
        _tickets = List.from(_demoTickets);
        notifyListeners();
      }
      return;
    }

    try {
      await _repository.markTicketAsRead(ticketId);
    } catch (e) {
      debugPrint('Error marking ticket as read: $e');
    }
  }

  @override
  void dispose() {
    stopWatchingTickets();
    stopWatchingMessages();
    super.dispose();
  }
}
