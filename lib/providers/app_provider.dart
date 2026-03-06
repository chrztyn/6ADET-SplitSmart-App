import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/groups_service.dart';
import '../services/expenses_service.dart';
import '../services/debts_service.dart';
import '../services/notifications_service.dart';
import '../services/supabase_client.dart';

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
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Real-time subscriptions
  StreamSubscription? _debtsSub;
  StreamSubscription? _notifSub;

  // =========== GETTERS ===========
  Map<String, dynamic>? get profile => _profile;
  List<Map<String, dynamic>> get myGroups => _myGroups;
  List<Map<String, dynamic>> get currentExpenses => _currentExpenses;
  List<Map<String, dynamic>> get myDebts => _myDebts;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => supabase.auth.currentUser != null;

  List<Map<String, dynamic>> get pendingDebtsIOwe =>
      _myDebts.where((d) => d['from_user_id'] == supabase.auth.currentUser?.id && d['status'] == 'pending').toList();

  List<Map<String, dynamic>> get pendingDebtsOwedToMe =>
      _myDebts.where((d) => d['to_user_id'] == supabase.auth.currentUser?.id && d['status'] == 'pending').toList();

  int get unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  // =========== INIT ===========
  Future<void> init() async {
    if (!isLoggedIn) return;
    await _loadAll();
    _subscribeRealtime();
  }

  Future<void> _loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _auth.getProfile(),
        _groups.getMyGroups(),
        _debts.getMyDebts(),
        _notifs.getNotifications(),
      ]);
      _profile = results[0] as Map<String, dynamic>;
      _myGroups = results[1] as List<Map<String, dynamic>>;
      _myDebts = results[2] as List<Map<String, dynamic>>;
      _notifications = results[3] as List<Map<String, dynamic>>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========== SUBSCRIPTION ===========
  void _subscribeRealtime() {
    _debtsSub = _debts.watchMyDebts().listen((data) async {
      _myDebts = await _debts.getMyDebts();
      notifyListeners();
    });

    _notifSub = _notifs.watchNotifications().listen((data) {
      _notifications = data;
      notifyListeners();
    });
  }

  void _cancelRealtime() {
    _debtsSub?.cancel();
    _notifSub?.cancel();
  }

  // =========== AUTHENTICATION ===========
  Future<void> register(String name, String email, String password) async {
    await _auth.register(name: name, email: email, password: password);
    await _loadAll();
    _subscribeRealtime();
  }

  Future<void> login(String email, String password) async {
    await _auth.login(email: email, password: password);
    await _loadAll();
    _subscribeRealtime();
  }

  Future<void> logout() async {
    _cancelRealtime();
    await _auth.logout();
    _profile = null;
    _myGroups = [];
    _currentExpenses = [];
    _myDebts = [];
    _notifications = [];
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    _profile = await _auth.updateProfile(name: name, email: email);
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

  Future<Map<String, dynamic>> createGroup(String name, String description, List<String> memberEmails) async {
    final group = await _groups.createGroup(name: name, description: description, memberEmails: memberEmails);
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

  Future<Map<String, double>> getGroupBalances(String groupId) async => await _groups.getGroupBalances(groupId);

  Future<Map<String, dynamic>?> findUserByEmail(String email) async => await _groups.findUserByEmail(email);

  // =========== EXPENSES ===========
  Future<void> loadGroupExpenses(String groupId, {String? search, String? category}) async {
    _currentExpenses = await _exps.getGroupExpenses(groupId, search: search, category: category);
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
    notifyListeners();
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _exps.deleteExpense(expenseId);
    await loadGroupExpenses(groupId);
    _myDebts = await _debts.getMyDebts();
    notifyListeners();
  }

  Future<double> getTotalExpenses(String groupId) async => await _exps.getTotalExpenses(groupId);

  // =========== DEBTS ===========
  Future<void> refreshDebts() async {
    _myDebts = await _debts.getMyDebts();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getGroupDebts(String groupId) async => await _debts.getGroupDebts(groupId);

  Future<void> settleDebt(String debtId, {required String paymentMethod, File? proofFile}) async {
    await _debts.settleDebt(debtId, paymentMethod: paymentMethod, proofFile: proofFile);
    await refreshDebts();
  }

  Future<({double iOwe, double owedToMe})> getDebtSummary() async => await _debts.getSummary();

  // =========== NOTIFS ===========
  Future<void> markAllNotificationsRead() async {
    await _notifs.markAllRead();
    for (final n in _notifications) {
      n['is_read'] = true;
    }
    notifyListeners();
  }

  // =========== CLEANUP ===========
  @override
  void dispose() {
    _cancelRealtime();
    super.dispose();
  }
}
