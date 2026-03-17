import 'dart:io';
import 'supabase_client.dart';

class ExpensesService {
  // =========== GET ALL EXPENSE OF GROUP ===========
  Future<List<Map<String, dynamic>>> getGroupExpenses(
    String groupId, {
    String? search,
    String? category,
  }) async {
    var query = supabase
        .from('expenses')
        .select('''
          *,
          paid_by:profiles!expenses_paid_by_user_id_fkey ( id, name, avatar_url ),
          splits:expense_splits (
            user:profiles ( id, name )
          )
        ''')
        .eq('group_id', groupId);

    if (search != null && search.isNotEmpty) {
      query = query.ilike('description', '%$search%');
    }

    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }

    final data = await query.order('date', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // =========== ADD EXPENSE + AUTO GENERATE DEBTS AND NOTIFY ===========
  Future<Map<String, dynamic>> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidByUserId,
    required List<String> splitBetween,
    required String category,
    required DateTime date,
    File? receiptFile,
  }) async {
    String? receiptUrl;

    if (receiptFile != null) {
      final ext = receiptFile.path.split('.').last;
      final path =
          '$currentUserId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from('receipts').upload(path, receiptFile);
      receiptUrl = supabase.storage.from('receipts').getPublicUrl(path);
    }

    final expense = await supabase
        .from('expenses')
        .insert({
          'group_id': groupId,
          'description': description,
          'amount': amount,
          'paid_by_user_id': paidByUserId,
          'category': category,
          'date': date.toIso8601String().split('T').first,
          ...?receiptUrl != null ? {'receipt_url': receiptUrl} : null,
        })
        .select()
        .single();

    final expenseId = expense['id'] as String;

    await supabase
        .from('expense_splits')
        .insert(
          splitBetween
              .map((uid) => {'expense_id': expenseId, 'user_id': uid})
              .toList(),
        );

    final share = double.parse(
      (amount / splitBetween.length).toStringAsFixed(2),
    );

    final debtRows = splitBetween
        .where((uid) => uid != paidByUserId)
        .map(
          (uid) => {
            'expense_id': expenseId,
            'group_id': groupId,
            'from_user_id': uid,
            'to_user_id': paidByUserId,
            'amount': share,
            'status': 'pending',
          },
        )
        .toList();

    if (debtRows.isNotEmpty) {
      await supabase.from('debts').insert(debtRows);
    }

    final notifRows = splitBetween
        .where((uid) => uid != paidByUserId)
        .map(
          (uid) => {
            'user_id': uid,
            'type': 'new_expense',
            'message':
                'New expense "$description" — your share is PHP ${share.toStringAsFixed(2)}',
          },
        )
        .toList();

    if (notifRows.isNotEmpty) {
      await supabase.from('notifications').insert(notifRows);
    }

    // Notify the payer as confirmation
    await supabase.from('notifications').insert({
      'user_id': paidByUserId,
      'type': 'new_expense',
      'message':
          'You added "$description" — PHP ${amount.toStringAsFixed(2)} split ${splitBetween.length} way${splitBetween.length > 1 ? 's' : ''} (PHP ${share.toStringAsFixed(2)} each).',
    });

    return expense;
  }

  // =========== UPDATE EXPENSE ===========
  Future<void> updateExpense(
    String expenseId, {
    String? description,
    double? amount,
    String? category,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      ...?description != null ? {'description': description} : null,
      ...?amount != null ? {'amount': amount} : null,
      ...?category != null ? {'category': category} : null,
    };

    await supabase.from('expenses').update(updates).eq('id', expenseId);
  }

  // =========== DELETE EXPENSE ===========
  Future<void> deleteExpense(String expenseId) async {
    await supabase.from('expenses').delete().eq('id', expenseId);
  }

  // =========== REAL TIME UPDATE EXPENSE OF A GROUP ===========
  Stream<List<Map<String, dynamic>>> watchGroupExpenses(String groupId) {
    return supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('date', ascending: false);
  }

  // =========== TOTAL EXPENSE OF GROUP ===========
  Future<double> getTotalExpenses(String groupId) async {
    final List<dynamic> data = await supabase
        .from('expenses')
        .select('amount')
        .eq('group_id', groupId);

    return data.fold<double>(
      0.0,
      (double sum, dynamic e) => sum + (e['amount'] as num).toDouble(),
    );
  }

  // =========== RECENT ACTIVITY ===========
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    // Get user's group IDs first
    final memberships = await supabase
        .from('group_members')
        .select('group_id')
        .eq('user_id', currentUserId);

    final groupIds = (memberships as List)
        .map((r) => r['group_id'] as String)
        .toList();

    if (groupIds.isEmpty) return [];

    final data = await supabase
        .from('expenses')
        .select('''
          id, description, amount, date,
          groups:group_id ( name ),
          profiles:paid_by_user_id ( name )
        ''')
        .inFilter('group_id', groupIds)
        .order('date', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(data);
  }

  // =========== CURRENT USER ID ===========
  String get currentUserId => supabase.auth.currentUser!.id;
}
