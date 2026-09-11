import 'package:equatable/equatable.dart';
import '../../models/session_model.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceHistory extends AttendanceEvent {}

class AddSessionRecord extends AttendanceEvent {
  final SessionModel session;

  const AddSessionRecord(this.session);

  @override
  List<Object?> get props => [session];
}
