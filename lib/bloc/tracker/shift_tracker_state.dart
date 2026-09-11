import 'package:equatable/equatable.dart';

enum ShiftStatus { offline, working, paused }

class ShiftTrackerState extends Equatable {
  final ShiftStatus status;
  final int normalWorkingSeconds;
  final int extraWorkingSeconds;
  final int totalWorkingSeconds;
  final int remainingSeconds;
  final int currentSessionSeconds;
  final int loginSessionsCount;

  static const int maxNormalSeconds = 8 * 3600; // 08:00:00 (28,800s)
  static const int maxExtraSeconds = 5 * 3600; // 05:00:00 (18,000s)
  static const int maxTotalSeconds = 13 * 3600; // 13:00:00 (46,800s)

  const ShiftTrackerState({
    required this.status,
    required this.normalWorkingSeconds,
    required this.extraWorkingSeconds,
    required this.totalWorkingSeconds,
    required this.remainingSeconds,
    required this.currentSessionSeconds,
    required this.loginSessionsCount,
  });

  // Initial demo state inspired by the web dashboard
  factory ShiftTrackerState.initial() {
    const initialWorking = 2100; // 35m 00s
    return const ShiftTrackerState(
      status: ShiftStatus.offline,
      normalWorkingSeconds: initialWorking,
      extraWorkingSeconds: 0,
      totalWorkingSeconds: initialWorking,
      remainingSeconds: maxTotalSeconds - initialWorking,
      currentSessionSeconds: 0,
      loginSessionsCount: 1,
    );
  }

  ShiftTrackerState copyWith({
    ShiftStatus? status,
    int? normalWorkingSeconds,
    int? extraWorkingSeconds,
    int? totalWorkingSeconds,
    int? remainingSeconds,
    int? currentSessionSeconds,
    int? loginSessionsCount,
  }) {
    return ShiftTrackerState(
      status: status ?? this.status,
      normalWorkingSeconds: normalWorkingSeconds ?? this.normalWorkingSeconds,
      extraWorkingSeconds: extraWorkingSeconds ?? this.extraWorkingSeconds,
      totalWorkingSeconds: totalWorkingSeconds ?? this.totalWorkingSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      currentSessionSeconds: currentSessionSeconds ?? this.currentSessionSeconds,
      loginSessionsCount: loginSessionsCount ?? this.loginSessionsCount,
    );
  }

  bool get isWorking => status == ShiftStatus.working;
  bool get isPaused => status == ShiftStatus.paused;
  bool get isOffline => status == ShiftStatus.offline;

  @override
  List<Object?> get props => [
        status,
        normalWorkingSeconds,
        extraWorkingSeconds,
        totalWorkingSeconds,
        remainingSeconds,
        currentSessionSeconds,
        loginSessionsCount,
      ];
}
