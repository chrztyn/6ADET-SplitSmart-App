import '../models/app_notification.dart';
import 'supabase_client.dart';

class NotificationsService {
  // =========== GET NOTIFS OF CURRENT USER ===========
  Future<List<AppNotification>> getNotifications() async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =========== MARK AS READ ===========
  Future<void> markAllRead() async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', currentUserId)
        .eq('is_read', false);
  }

  // =========== REAL TIME UPDATE  ===========
  Stream<List<AppNotification>> watchNotifications() {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((e) => AppNotification.fromJson(e)).toList());
  }

  // =========== UNREAD NOTIFS COUNT  ===========
  Future<int> getUnreadCount() async {
    final data = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('is_read', false);
    return (data as List).length;
  }
}
