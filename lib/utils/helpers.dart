import 'package:intl/intl.dart';
import 'dart:io';

String formatCurrency(double amount) =>
    'PHP ${NumberFormat('#,##0.00').format(amount)}';

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

/// Returns a human-readable error message from any exception.
String friendlyError(Object e) {
  if (e is SocketException || e.toString().contains('SocketException')) {
    return 'No internet connection. Please check your Wi-Fi or mobile data.';
  }
  if (e.toString().contains('Failed host lookup') ||
      e.toString().contains('Network is unreachable')) {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  if (e.toString().contains('401') || e.toString().contains('403')) {
    return 'Session expired. Please log in again.';
  }
  if (e.toString().contains('404')) {
    return 'The requested data was not found.';
  }
  if (e.toString().contains('500') ||
      e.toString().contains('502') ||
      e.toString().contains('503')) {
    return 'Server error. Please try again later.';
  }
  if (e.toString().contains('timeout') ||
      e.toString().contains('TimeoutException')) {
    return 'Request timed out. Please try again.';
  }
  // Supabase PostgrestException includes a readable message
  final msg = e.toString();
  if (msg.startsWith('PostgrestException:')) {
    return msg.replaceFirst('PostgrestException: ', '');
  }
  return 'Something went wrong. Please try again.';
}
