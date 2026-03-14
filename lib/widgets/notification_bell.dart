import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/notifications_screen.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();

  @override
  void dispose() {
    if (_controller.isShowing) _controller.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final unreadCount = provider.unreadCount;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (_) => _NotifOverlay(
          link: _link,
          notifications: provider.notifications,
          unreadCount: unreadCount,
          onClose: _controller.hide,
          onMarkAllRead: () async {
            await provider.markAllNotificationsRead();
            _controller.hide();
          },
          onViewAll: () {
            _controller.hide();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        child: GestureDetector(
          onTap: () =>
              _controller.isShowing ? _controller.hide() : _controller.show(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    230,
                    245,
                    255,
                  ).withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  unreadCount > 0
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                  color: const Color(0xFF038AFF),
                  size: 22,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B3B),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overlay dropdown ──────────────────────────────────────────────────────────

class _NotifOverlay extends StatelessWidget {
  final LayerLink link;
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final VoidCallback onClose;
  final VoidCallback onMarkAllRead;
  final VoidCallback onViewAll;

  const _NotifOverlay({
    required this.link,
    required this.notifications,
    required this.unreadCount,
    required this.onClose,
    required this.onMarkAllRead,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tap-outside barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            shadowColor: const Color(0xFF038AFF).withOpacity(0.15),
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCF2FF), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                    child: Row(
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003CC1),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B3B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount new',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (unreadCount > 0)
                          TextButton(
                            onPressed: onMarkAllRead,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Mark all read',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: const Color(0xFF038AFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFEEF5FF)),

                  // notifications (or empty state)
                  if (notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFEEF5FF),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (_, i) =>
                            _NotifTile(notification: notifications[i]),
                      ),
                    ),

                  if (notifications.isNotEmpty) ...[
                    const Divider(height: 1, color: Color(0xFFEEF5FF)),
                    InkWell(
                      onTap: onViewAll,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'View all notifications',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF038AFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Individual tile ────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotifTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final isRead = notification['is_read'] as bool? ?? true;
    final createdAt = notification['created_at'] as String? ?? '';

    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (type) {
      case 'new_expense':
        icon = Icons.receipt_long_outlined;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF038AFF);
        break;
      case 'debt_settled':
        icon = Icons.check_circle_outline;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF2E7D32);
        break;
      default:
        icon = Icons.notifications_outlined;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF038AFF);
    }

    return Container(
      color: isRead ? Colors.transparent : const Color(0xFFF0F8FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(createdAt),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF038AFF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String createdAt) {
    if (createdAt.isEmpty) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
