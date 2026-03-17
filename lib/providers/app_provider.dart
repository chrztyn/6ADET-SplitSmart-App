import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/groups_service.dart';
import '../services/expenses_service.dart';
import '../services/debts_service.dart';
import '../models/app_notification.dart';
import '../services/notifications_service.dart';
import '../services/supabase_client.dart';
import '../utils/local_notifications_helper.dart';

class AppProvider extends ChangeNotifier {
  // =========== SERVICES ===========
  final _auth = AuthService();
  final _groups = GroupsService();
  final _exps = ExpensesService();
  final _debts = DebtsService();
  final _notifs = NotificationsService();

  // =========== STATE ===========
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _currentExpenses = [];
  List<Map<String, dynamic>> _myDebts = [];
  List<AppNotification> _notifications = [];
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = false;
  String? _error;

  // Real-time subscriptions
  StreamSubscription? _debtsSub;
  StreamSubscription? _notifSub;
  bool _initialized = false;

  // Track latest notification timestamp to detect new arrivals
  DateTime? _latestNotifTimestamp;

  // =========== GETTERS ===========
  Map<String, dynamic>? get profile => _profile;
  List<Map<String, dynamic>> get myGroups => _myGroups;
  List<Map<String, dynamic>> get currentExpenses => _currentExpenses;
  List<Map<String, dynamic>> get myDebts => _myDebts;
  List<AppNotification> get notifications => _notifications;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => supabase.auth.currentUser != null;

  List<Map<String, dynamic>> get pendingDebtsIOwe => _myDebts
      .where(
        (d) =>
            d['from_user_id'] == supabase.auth.currentUser?.id &&
            d['status'] == 'pending',
      )
      .toList();

  List<Map<String, dynamic>> get pendingDebtsOwedToMe => _myDebts
      .where(
        (d) =>
            d['to_user_id'] == supabase.auth.currentUser?.id &&
            d['status'] == 'pending',
      )
      .toList();

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // =========== INIT ===========
  Future<void> init() async {
    if (!isLoggedIn) return;
    if (_initialized) return;
    _initialized = true;
    await _loadAll();
    _subscribeRealtime();
    // Retry loading debts after short delay to ensure auth session
    // is fully ready before the .or() filter runs
    await Future.delayed(const Duration(milliseconds: 800));
    if (isLoggedIn) {
      _myDebts = await _debts.getMyDebts();
      notifyListeners();
    }
  }

  Future<void> _loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final results = await Future.wait([
      _auth.getProfile(),
      _groups.getMyGroups(),
      _debts.getMyDebts(),
      _notifs.getNotifications(),
      _exps.getRecentActivity(),
    ]);
    _profile = results[0] as Map<String, dynamic>;
    _myGroups = results[1] as List<Map<String, dynamic>>;
    _myDebts = results[2] as List<Map<String, dynamic>>;
    _notifications = results[3] as List<AppNotification>;
    _recentActivity = results[4] as List<Map<String, dynamic>>;
    // Seed the latest timestamp so first realtime update doesn't re-notify
    if (_notifications.isNotEmpty) {
      _latestNotifTimestamp = _notifications.first.createdAt;
    }
    _isLoading = false;
    notifyListeners();
  }

  // =========== SUBSCRIPTION ===========
  void _subscribeRealtime() {
    _debtsSub = _debts.watchMyDebts().listen((data) async {
      _myDebts = await _debts.getMyDebts();
      notifyListeners();
    });

    _notifSub = _notifs.watchNotifications().listen((data) {
      // Detect genuinely new notifications and fire OS push notifications
      if (_latestNotifTimestamp != null) {
        for (final notif in data) {
          if (notif.createdAt.isAfter(_latestNotifTimestamp!)) {
            LocalNotificationsHelper.showNotification(
              title: LocalNotificationsHelper.titleForType(notif.type),
              body: notif.message.isEmpty ? 'New notification' : notif.message,
              id: notif.id.hashCode,
            );
          }
        }
      }
      // Only overwrite if stream returned data, to avoid clearing
      // a valid list on a spurious empty emission at startup
      if (data.isNotEmpty || _notifications.isEmpty) {
        _notifications = data;
      }
      if (_notifications.isNotEmpty) {
        _latestNotifTimestamp = _notifications.first.createdAt;
      }
      notifyListeners();
    });
  }

  void _cancelRealtime() {
    _debtsSub?.cancel();
    _notifSub?.cancel();
    _debtsSub = null;
    _notifSub = null;
    try {
      supabase.removeAllChannels();
    } catch (_) {}
  }

  // =========== AUTHENTICATION ===========
  Future<void> register(String name, String email, String password) async {
    await _auth.register(name: name, email: email, password: password);
    _initialized = true;
    await _loadAll();
    _subscribeRealtime();
  }

  Future<void> login(String email, String password) async {
    await _auth.login(email: email, password: password);
    _initialized = true;
    await _loadAll();
    _subscribeRealtime();
  }

  Future<void> logout() async {
    _cancelRealtime();
    await Future.delayed(const Duration(milliseconds: 300));
    await _auth.logout();
    _profile = null;
    _initialized = false;
    _myGroups = [];
    _currentExpenses = [];
    _myDebts = [];
    _notifications = <AppNotification>[];
    _recentActivity = [];
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email, {String? phone}) async {
    _profile = await _auth.updateProfile(
      name: name,
      email: email,
      phone: phone,
    );
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _profile = await _auth.getProfile();
    notifyListeners();
  }

  Future<void> uploadAvatar(File file) async {
    final url = await _auth.uploadAvatar(file);
    _profile = {...?_profile, 'avatar_url': url};
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await _auth.signInWithGoogle();
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPassword(email);
  }

  // =========== GROUPS ===========
  Future<void> refreshGroups() async {
    _myGroups = await _groups.getMyGroups();
    notifyListeners();
  }

  Future<Map<String, dynamic>> createGroup(
    String name,
    String description,
    List<String> memberEmails,
  ) async {
    final group = await _groups.createGroup(
      name: name,
      description: description,
      memberEmails: memberEmails,
    );
    await refreshGroups();
    return group;
  }

  Future<void> addMembers(String groupId, List<String> emails) async {
    await _groups.addMembers(groupId, emails);
    await refreshGroups();
  }

  Future<void> deleteGroup(String groupId) async {
    await _groups.deleteGroup(groupId);
    await refreshGroups();
  }

  Future<Map<String, double>> getGroupBalances(String groupId) async =>
      await _groups.getGroupBalances(groupId);

  Future<Map<String, dynamic>?> findUserByEmail(String email) async =>
      await _groups.findUserByEmail(email);

  Future<Map<String, dynamic>> getGroup(String groupId) async =>
      await _groups.getGroup(groupId);

  // =========== EXPENSES ===========

  // ADDED - get expenses for a specific group
  Future<List<Map<String, dynamic>>> getGroupExpenses(String groupId) async {
    return await _exps.getGroupExpenses(groupId);
  }

  Future<void> loadGroupExpenses(
    String groupId, {
    String? search,
    String? category,
  }) async {
    _currentExpenses = await _exps.getGroupExpenses(
      groupId,
      search: search,
      category: category,
    );
    notifyListeners();
  }

  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidByUserId,
    required List<String> splitBetween,
    required String category,
    required DateTime date,
    File? receiptFile,
  }) async {
    await _exps.addExpense(
      groupId: groupId,
      description: description,
      amount: amount,
      paidByUserId: paidByUserId,
      splitBetween: splitBetween,
      category: category,
      date: date,
      receiptFile: receiptFile,
    );
    await loadGroupExpenses(groupId);
    _myDebts = await _debts.getMyDebts();
    _recentActivity = await _exps.getRecentActivity(); // ADDED
    notifyListeners();
  }

  // FIXED - only takes expenseId, no groupId needed
  Future<void> deleteExpense(String expenseId) async {
    await _exps.deleteExpense(expenseId);
    _myDebts = await _debts.getMyDebts();
    _recentActivity = await _exps.getRecentActivity(); // ADDED
    notifyListeners();
  }

  Future<double> getTotalExpenses(String groupId) async =>
      await _exps.getTotalExpenses(groupId);

  // =========== DEBTS ===========
  Future<List<Map<String, dynamic>>> getMyDebts({String? status}) async =>
      await _debts.getMyDebts(status: status);

  Future<void> refreshDebts() async {
    _myDebts = await _debts.getMyDebts();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getGroupDebts(String groupId) async =>
      await _debts.getGroupDebts(groupId);

  Future<void> settleDebt(
    String debtId, {
    required String paymentMethod,
    required double amount,
    File? proofFile,
  }) async {
    await _debts.settleDebt(
      debtId,
      paymentMethod: paymentMethod,
      amount: amount,
      proofFile: proofFile,
    );
    await refreshDebts();
  }

  Future<({double iOwe, double owedToMe})> getDebtSummary() async =>
      await _debts.getSummary();

  // =========== NOTIFS ===========
  Future<void> markAllNotificationsRead() async {
    await _notifs.markAllRead();
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  // =========== CLEANUP ===========
  @override
  void dispose() {
    _cancelRealtime();
    super.dispose();
  }
}
