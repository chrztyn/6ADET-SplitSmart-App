import 'supabase_client.dart';

class GroupsService {
  // =========== CURRENT USER ID ===========
  String get currentUserId => supabase.auth.currentUser!.id;

  // =========== GET ALL GROUPS ===========
  Future<List<Map<String, dynamic>>> getMyGroups() async {
    // Step 1 - get group IDs the user belongs to
    final memberships = await supabase.from('group_members').select('group_id').eq('user_id', currentUserId);

    final groupIds = (memberships as List).map((r) => r['group_id'] as String).toList();

    if (groupIds.isEmpty) return [];

    // Step 2 - fetch group details
    final groups = await supabase
        .from('groups')
        .select('id, name, description, created_by, created_at')
        .inFilter('id', groupIds);

    // Step 3 - add member_count to each group
    final result = <Map<String, dynamic>>[];
    for (final g in groups as List) {
      final countData = await supabase.from('group_members').select('user_id').eq('group_id', g['id'] as String);
      final map = Map<String, dynamic>.from(g);
      map['member_count'] = (countData as List).length;
      result.add(map);
    }
    return result;
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

  // =========== WATCH GROUP MEMBER CHANGES ===========
  Stream<List<Map<String, dynamic>>> watchMyGroups() {
    return supabase.from('group_members').stream(primaryKey: ['id']).eq('user_id', currentUserId);
  }

  // =========== SEARCH GROUPS BY NAME ===========
  Future<List<Map<String, dynamic>>> searchGroups(String query) async {
    final allGroups = await getMyGroups();
    final q = query.toLowerCase();
    return allGroups.where((g) => (g['name'] as String).toLowerCase().contains(q)).toList();
  }

  // =========== FIND USER BY EMAIL ===========
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    return await supabase.from('profiles').select('id, name, email').eq('email', email).maybeSingle();
  }
}
