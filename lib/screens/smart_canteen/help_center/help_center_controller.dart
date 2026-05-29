import 'dart:async';

import 'package:flutter/foundation.dart';

import 'help_center_model.dart';

class HelpCenterController extends ChangeNotifier {
  List<FAQModel> _faqs = const [];
  List<SupportTicketModel> _tickets = const [];
  HelpCategory _category = HelpCategory.all;
  String _query = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _submitting = false;
  bool _hasError = false;
  bool _disposed = false;
  Timer? _loadTimer;
  Timer? _refreshTimer;
  Timer? _submitTimer;
  Completer<void>? _refreshCompleter;
  Completer<bool>? _submitCompleter;

  HelpCategory get category => _category;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get submitting => _submitting;
  bool get hasError => _hasError;
  List<SupportTicketModel> get tickets => _tickets;

  List<FAQModel> get visibleFaqs {
    final query = _query.trim().toLowerCase();
    return _faqs
        .where((faq) {
          if (_category != HelpCategory.all && faq.category != _category) {
            return false;
          }
          if (query.isEmpty) return true;
          return '${faq.question} ${faq.answer} ${helpCategoryLabel(faq.category)}'
              .toLowerCase()
              .contains(query);
        })
        .toList(growable: false);
  }

  void load() {
    _loadTimer?.cancel();
    _loading = true;
    _hasError = false;
    _notify();
    _loadTimer = Timer(const Duration(milliseconds: 430), () {
      if (_disposed) return;
      _faqs = List<FAQModel>.of(demoFaqs);
      _tickets = List<SupportTicketModel>.of(demoSupportTickets);
      _loading = false;
      _notify();
    });
  }

  Future<void> refresh() {
    if (_refreshing) return _refreshCompleter?.future ?? Future<void>.value();
    _refreshing = true;
    _notify();
    _refreshCompleter = Completer<void>();
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 520), () {
      if (_disposed) {
        _refreshCompleter?.complete();
        return;
      }
      _refreshing = false;
      _notify();
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    });
    return _refreshCompleter!.future;
  }

  void updateSearch(String value) {
    if (_query == value) return;
    _query = value;
    _notify();
  }

  void clearSearch() => updateSearch('');

  void setCategory(HelpCategory category) {
    if (_category == category) return;
    _category = category;
    _notify();
  }

  int countFor(HelpCategory category) {
    if (category == HelpCategory.all) return _faqs.length;
    return _faqs.where((faq) => faq.category == category).length;
  }

  Future<bool> submitTicket(ProblemType type, String description) {
    if (_submitting) {
      return _submitCompleter?.future ?? Future<bool>.value(false);
    }
    _submitting = true;
    _notify();
    _submitCompleter = Completer<bool>();
    _submitTimer?.cancel();
    _submitTimer = Timer(const Duration(milliseconds: 650), () {
      if (_disposed) {
        _submitCompleter?.complete(false);
        return;
      }
      final id =
          'SPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _tickets = [
        SupportTicketModel(
          id: id,
          type: type,
          title: '${problemTypeLabel(type)} cần hỗ trợ',
          description: description,
          status: SupportStatus.processing,
          submittedAt: 'Vừa xong',
        ),
        ..._tickets,
      ];
      _submitting = false;
      _notify();
      _submitCompleter?.complete(true);
      _submitCompleter = null;
    });
    return _submitCompleter!.future;
  }

  void closeTicket(String id) {
    _tickets = _tickets
        .map((ticket) {
          if (ticket.id != id) return ticket;
          return ticket.copyWith(status: SupportStatus.closed);
        })
        .toList(growable: false);
    _notify();
  }

  void retry() => load();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadTimer?.cancel();
    _refreshTimer?.cancel();
    _submitTimer?.cancel();
    if (!(_refreshCompleter?.isCompleted ?? true)) {
      _refreshCompleter?.complete();
    }
    if (!(_submitCompleter?.isCompleted ?? true)) {
      _submitCompleter?.complete(false);
    }
    super.dispose();
  }
}
