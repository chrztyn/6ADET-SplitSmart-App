import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/app_provider.dart';
import '../widgets/skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().markAllNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6FAFC), Color(0xFFDCF2FF), Color(0xFFB4E4FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Custom App Bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDCF2FF),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Color(0xFF003CC1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF003CC1),
                          Color(0xFF038AFF),
                          Color(0xFF01A7FF),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Notifications',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (notifications.any((n) => !n.isRead))
                      TextButton(
                        onPressed: () => provider.markAllNotificationsRead(),
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF038AFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: provider.isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: 6,
                        itemBuilder: (_, __) => const SkeletonListItem(
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => provider.init(),
                        child: notifications.isEmpty
                            ? _buildEmpty()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                itemCount: notifications.length,
                                itemBuilder: (_, i) =>
                                    _NotifCard(notification: notifications[i]),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF038AFF).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 72,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003CC1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll be notified about new expenses and debt settlements here.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notification;

  const _NotifCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final type = notification.type;
    final message = notification.message;
    final isRead = notification.isRead;
    final createdAt = notification.createdAt.toIso8601String();

    IconData icon;
    Color iconBg;
    Color iconColor;
    String typeLabel;

    switch (type) {
      case 'new_expense':
        icon = Icons.receipt_long_outlined;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF038AFF);
        typeLabel = 'New Expense';
        break;
      case 'debt_settled':
        icon = Icons.check_circle_outline;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF2E7D32);
        typeLabel = 'Debt Settled';
        break;
      default:
        icon = Icons.notifications_outlined;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF038AFF);
        typeLabel = 'Notification';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? const Color(0xFFDCF2FF)
              : const Color(0xFF038AFF).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF038AFF).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF038AFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(createdAt),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
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
