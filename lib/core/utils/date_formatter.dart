class DateFormatter {
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return '오늘';
    if (difference.inDays == 1) return '어제';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}주 전';
    return '${(difference.inDays / 30).floor()}개월 전';
  }
}
