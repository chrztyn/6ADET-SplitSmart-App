import 'supabase_client.dart';

class GroupsService {
  // =========== GET ALL GROUPS ===========
  Future<List<Map<String, dynamic>>> getMyGroups() async {
    final data = await supabase
        .from('group_members')
        .select('''
          group:groups (
            id, name, description, created_by, created_at,
            members:group_members (
              user:profiles ( id, name, email, avatar_url )
            )
          )
        ''')
        .eq('user_id', currentUserId);

    return (data as List).map((row) => row['group'] as Map<String, dynamic>).toList();
  }

  // =========== GET SINGLE GROUP ===========
  Future<Map<String, dynamic>> getGroup(String groupId) async {
    return await supabase
        .from('groups')
        .select('''
          *,
          members:group_members (
            user:profiles ( id, name, email, avatar_url )
          )
        ''')
        .eq('id', groupId)
        .single();
  }

  // =========== CREATE GROUP ===========
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String description,
    required List<String> memberEmails,
  }) async {
    // 1. Create group
    final group = await supabase
        .from('groups')
        .insert({'name': name, 'description': description, 'created_by': currentUserId})
        .select()
        .single();

    // 2. Resolve emails → user IDs
    final memberIds = <String>{currentUserId};
    if (memberEmails.isNotEmpty) {
      final profiles = await supabase.from('profiles').select('id').inFilter('email', memberEmails);
      for (final p in profiles as List) {
        memberIds.add(p['id'] as String);
      }
    }

    // 3. Insert group_members
    await supabase
        .from('group_members')
        .insert(memberIds.map((uid) => {'group_id': group['id'], 'user_id': uid}).toList());

    return await getGroup(group['id'] as String);
  }

  // =========== ADD MEMBERS BY EMAIL ===========
  Future<void> addMembers(String groupId, List<String> emails) async {
    if (emails.isEmpty) return;

    final profiles = await supabase.from('profiles').select('id').inFilter('email', emails);

    final rows = (profiles as List).map((p) => {'group_id': groupId, 'user_id': p['id']}).toList();

    if (rows.isNotEmpty) {
      await supabase.from('group_members').upsert(rows, onConflict: 'group_id,user_id');
    }
  }

  // =========== DELETE GROUP ===========
  Future<void> deleteGroup(String groupId) async {
    await supabase.from('groups').delete().eq('id', groupId);
  }

  // =========== BALANCE SUMMARY OF GROUP ===========
  Future<Map<String, double>> getGroupBalances(String groupId) async {
    final debts = await supabase
        .from('debts')
        .select('from_user_id, to_user_id, amount')
        .eq('group_id', groupId)
        .eq('status', 'pending');

    final balances = <String, double>{};
    for (final d in debts as List) {
      final from = d['from_user_id'] as String;
      final to = d['to_user_id'] as String;
      final amount = (d['amount'] as num).toDouble();
      balances[to] = (balances[to] ?? 0) + amount;
      balances[from] = (balances[from] ?? 0) - amount;
    }
    return balances;
  }

  // =========== GROUP MEMBER CHANGES ===========
  Stream<List<Map<String, dynamic>>> watchMyGroups() {
    return supabase.from('group_members').stream(primaryKey: ['id']).eq('user_id', currentUserId);
  }

  // =========== SEARCH GROUP BY NAMES ===========
  Future<List<Map<String, dynamic>>> searchGroups(String query) async {
    final allGroups = await getMyGroups();
    final q = query.toLowerCase();
    return allGroups.where((g) => (g['name'] as String).toLowerCase().contains(q)).toList();
  }

  // ======= FIND USERS BY EMAIL WHEN ADDING  ========
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final data = await supabase.from('profiles').select('id, name, email').eq('email', email).maybeSingle();
    return data;
  }
}
