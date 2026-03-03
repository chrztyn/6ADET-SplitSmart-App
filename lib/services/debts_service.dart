import 'dart:io';
import 'supabase_client.dart';

class DebtsService {
  // =========== ALL DEBTS ===========
  Future<List<Map<String, dynamic>>> getMyDebts({String? status}) async {
    var query = supabase
        .from('debts')
        .select('''
          *,
          from_user:profiles!debts_from_user_id_fkey ( id, name, avatar_url ),
          to_user:profiles!debts_to_user_id_fkey ( id, name, avatar_url ),
          group:groups ( id, name ),
          expense:expenses ( id, description )
        ''')
        .or('from_user_id.eq.$currentUserId,to_user_id.eq.$currentUserId');

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // =========== DEBT OF A SPECIFIC GROUP ===========
  Future<List<Map<String, dynamic>>> getGroupDebts(String groupId, {String? status}) async {
    var query = supabase
        .from('debts')
        .select('''
          *,
          from_user:profiles!debts_from_user_id_fkey ( id, name, avatar_url ),
          to_user:profiles!debts_to_user_id_fkey ( id, name, avatar_url ),
          expense:expenses ( id, description )
        ''')
        .eq('group_id', groupId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // =========== SETTLE DEBT ===========
  Future<void> settleDebt(String debtId, {required String paymentMethod, File? proofFile}) async {
    String? proofUrl;

    if (proofFile != null) {
      final ext = proofFile.path.split('.').last;
      final path = '$currentUserId/proof_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from('receipts').upload(path, proofFile);
      proofUrl = supabase.storage.from('receipts').getPublicUrl(path);
    }

    final debt = await supabase.from('debts').select('to_user_id, amount').eq('id', debtId).single();

    await supabase
        .from('debts')
        .update({
          'status': 'settled',
          'payment_method': paymentMethod,
          'settled_at': DateTime.now().toIso8601String(),
          'proof_url': ?proofUrl,
        })
        .eq('id', debtId);

    await supabase.from('notifications').insert({
      'user_id': debt['to_user_id'],
      'type': 'debt_settled',
      'message': 'A debt of PHP ${(debt['amount'] as num).toStringAsFixed(2)} was settled via $paymentMethod.',
    });
  }

  // =========== NET BALANCE SUMMARY ===========
  Future<({double iOwe, double owedToMe})> getSummary() async {
    final data = await supabase
        .from('debts')
        .select('from_user_id, to_user_id, amount')
        .or('from_user_id.eq.$currentUserId,to_user_id.eq.$currentUserId')
        .eq('status', 'pending');

    double iOwe = 0;
    double owedToMe = 0;

    for (final d in data as List) {
      final amount = (d['amount'] as num).toDouble();
      if (d['from_user_id'] == currentUserId) iOwe += amount;
      if (d['to_user_id'] == currentUserId) owedToMe += amount;
    }

    return (iOwe: iOwe, owedToMe: owedToMe);
  }

  // =========== REAL TIME UPDATE OF DEBTS ===========
  Stream<List<Map<String, dynamic>>> watchMyDebts() {
    return supabase.from('debts').stream(primaryKey: ['id']).order('created_at', ascending: false);
  }
}
