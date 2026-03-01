import 'supabase_client.dart';

class NotificationsService {
  // =========== GET NOTIFS OF CURRENT USER ===========
  Future<List<Map<String, dynamic>>> getNotifications() async {
    return List<Map<String, dynamic>>.from(
      await supabase.from('notifications').select().eq('user_id', currentUserId).order('created_at', ascending: false),
    );
  }

  // =========== MARK AS READ ===========
  Future<void> markAllRead() async {
    await supabase.from('notifications').update({'is_read': true}).eq('user_id', currentUserId).eq('is_read', false);
  }

  // =========== REAL TIME UPDATE  ===========
  Stream<List<Map<String, dynamic>>> watchNotifications() {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);
  }

  // =========== UNREAD NOTIFS COUNT  ===========
  Future<int> getUnreadCount() async {
    final data = await supabase.from('notifications').select('id').eq('user_id', currentUserId).eq('is_read', false);
    return (data as List).length;
  }
}
