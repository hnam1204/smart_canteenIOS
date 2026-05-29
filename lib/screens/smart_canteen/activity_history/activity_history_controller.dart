import 'dart:async';

import 'package:flutter/foundation.dart';

import 'activity_model.dart';

class ActivityHistoryController extends ChangeNotifier {
  final DateTime _now = DateTime(2026, 5, 25, 23, 59);
  List<ActivityModel> _activities = const [];
  ActivityFilterModel _filter = const ActivityFilterModel();
  String _query = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _hasError = false;
  bool _disposed = false;
  Timer? _loadTimer;
  Timer? _refreshTimer;
  Completer<void>? _refreshCompleter;

  ActivityFilterModel get filter => _filter;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get hasError => _hasError;

  int get totalActivities => _activities.length;
  int get orderedCount =>
      _activities.where((item) => item.type == ActivityType.order).length;
  int get loginCount =>
      _activities.where((item) => item.title.contains('Đăng nhập')).length;
  int get rewardCount =>
      _activities.where((item) => item.type == ActivityType.reward).length;

  List<ActivityModel> get visibleActivities {
    final normalized = _query.trim().toLowerCase();
    return _activities
        .where((item) {
          if (!_matchesType(item, _filter.type)) {
            return false;
          }
          if (_filter.status != null && item.status != _filter.status) {
            return false;
          }
          if (!_matchesPeriod(item, _filter.period)) {
            return false;
          }
          if (normalized.isEmpty) {
            return true;
          }
          final searchable =
              '${item.title} ${item.description} ${item.timeLabel} ${item.referenceCode ?? ''}'
                  .toLowerCase();
          return searchable.contains(normalized);
        })
        .toList(growable: false);
  }

  Map<ActivityDayGroup, List<ActivityModel>> get groupedActivities {
    final groups = <ActivityDayGroup, List<ActivityModel>>{};
    for (final activity in visibleActivities) {
      groups.putIfAbsent(activity.dayGroup, () => []).add(activity);
    }
    return groups;
  }

  void load() {
    _loadTimer?.cancel();
    _loading = true;
    _hasError = false;
    _notify();
    _loadTimer = Timer(const Duration(milliseconds: 430), () {
      if (_disposed) return;
      _activities = List<ActivityModel>.of(demoActivities);
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

  void setType(ActivityType type) {
    if (_filter.type == type) return;
    _filter = _filter.copyWith(type: type);
    _notify();
  }

  void applyAdvancedFilter(ActivityFilterModel filter) {
    _filter = filter;
    _notify();
  }

  void resetFilters() {
    _filter = const ActivityFilterModel();
    _notify();
  }

  int countFor(ActivityType type) {
    return _activities.where((item) => _matchesType(item, type)).length;
  }

  bool _matchesType(ActivityModel item, ActivityType type) {
    return type == ActivityType.all || item.type == type;
  }

  bool _matchesPeriod(ActivityModel item, ActivityPeriod period) {
    final days = _now.difference(item.occurredAt).inDays;
    return switch (period) {
      ActivityPeriod.all => true,
      ActivityPeriod.today => days == 0,
      ActivityPeriod.last7Days => days <= 7,
      ActivityPeriod.last30Days || ActivityPeriod.custom => days <= 30,
    };
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
    if (!(_refreshCompleter?.isCompleted ?? true)) {
      _refreshCompleter?.complete();
    }
    super.dispose();
  }
}
