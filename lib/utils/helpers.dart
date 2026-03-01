import 'package:intl/intl.dart';

String formatCurrency(double amount) => 'PHP ${NumberFormat('#,##0.00').format(amount)}';

String formatDate(String isoDate) {
  try {
    return DateFormat('MMM d, yyyy').format(DateTime.parse(isoDate));
  } catch (_) {
    return isoDate;
  }
}

String timeAgo(String isoDate) {
  try {
    final diff = DateTime.now().difference(DateTime.parse(isoDate));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  } catch (_) {
    return '';
  }
}

/// Safely convert Supabase numeric to double
double toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
