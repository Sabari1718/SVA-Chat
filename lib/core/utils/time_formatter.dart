class TimeFormatter {
  /// Formats seconds into HH:mm:ss format (e.g., 00:33:31)
  static String formatHms(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats seconds into 'Xh Ym' format (e.g., 0h 35m)
  static String formatHoursMinutes(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  /// Formats seconds into 'Xh Ym Zs' format (e.g., 00h 00m 00s)
  static String formatFullText(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }
}
