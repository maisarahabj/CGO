import 'package:campus_go/features/bookings/models/booking_model.dart';
import 'package:campus_go/features/profile/models/profile_model.dart';
import 'package:campus_go/features/timetable/models/schedule_model.dart';
import 'package:campus_go/features/timetable/models/timetable_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileModel JSON mapping', () {
    test('converts a complete Supabase profile row correctly', () {
      final profile = ProfileModel.fromJson({
        'id': '00000000-0000-0000-0000-000000000002',
        'full_name': 'Test Student',
        'unimy_id': 'B02',
        'dob': '2000-05-17',
        'prof_pic': 'https://example.com/profile.jpg',
        'role': 'student',
        'created_at': '2026-07-01T08:30:00Z',
      });

      expect(profile.id, '00000000-0000-0000-0000-000000000002');
      expect(profile.fullName, 'Test Student');
      expect(profile.unimyId, 'B02');
      expect(profile.dob, DateTime(2000, 5, 17));
      expect(profile.profPic, 'https://example.com/profile.jpg');
      expect(profile.role, 'student');
      expect(profile.createdAt, DateTime.utc(2026, 7, 1, 8, 30));

      final json = profile.toJson();

      expect(json['id'], profile.id);
      expect(json['full_name'], 'Test Student');
      expect(json['unimy_id'], 'B02');
      expect(json['dob'], '2000-05-17');
      expect(json['prof_pic'], profile.profPic);
      expect(json['role'], 'student');

      expect(DateTime.parse(json['created_at'] as String), profile.createdAt);
    });

    test('accepts nullable profile columns', () {
      final profile = ProfileModel.fromJson({
        'id': '00000000-0000-0000-0000-000000000003',
        'full_name': null,
        'unimy_id': null,
        'dob': null,
        'prof_pic': null,
        'role': 'lecturer',
        'created_at': null,
      });

      expect(profile.fullName, isNull);
      expect(profile.unimyId, isNull);
      expect(profile.dob, isNull);
      expect(profile.profPic, isNull);
      expect(profile.role, 'lecturer');
      expect(profile.createdAt, isNull);
    });
  });

  group('BookingModel JSON mapping', () {
    test('converts a complete Supabase booking row correctly', () {
      final booking = BookingModel.fromJson({
        'booking_id': 'BK001',
        'user_id': '00000000-0000-0000-0000-000000000002',
        'book_date': '2026-08-04',
        'book_start_time': '10:00:00',
        'book_end_time': '12:00:00',
        'room_node_id': 'L8_N14',
        'session_type': 'Group Study',
        'additional_info': 'Four students attending',
        'status': 'approved',
        'reason': 'Database project discussion',
        'created_at': '2026-08-01T01:30:00Z',
      });

      expect(booking.bookingId, 'BK001');
      expect(booking.userId, '00000000-0000-0000-0000-000000000002');
      expect(booking.bookDate, DateTime(2026, 8, 4));
      expect(booking.bookStartTime, '10:00:00');
      expect(booking.bookEndTime, '12:00:00');
      expect(booking.roomNodeId, 'L8_N14');
      expect(booking.sessionType, 'Group Study');
      expect(booking.additionalInfo, 'Four students attending');
      expect(booking.status, 'approved');
      expect(booking.reason, 'Database project discussion');
      expect(booking.createdAt, DateTime.utc(2026, 8, 1, 1, 30));

      final json = booking.toJson();

      expect(json['booking_id'], 'BK001');
      expect(json['book_date'], '2026-08-04');
      expect(json['book_start_time'], '10:00:00');
      expect(json['book_end_time'], '12:00:00');
      expect(json['room_node_id'], 'L8_N14');
      expect(json['status'], 'approved');
    });
  });

  group('TimetableModel JSON mapping', () {
    test('converts a Supabase timetable row correctly', () {
      final timetable = TimetableModel.fromJson({
        // A double is used deliberately to test num-to-int conversion.
        'timetable_id': 9.0,
        'room_node_id': 'L8_N14',
        'room_name': 'Elixr',
        'subject_code': 'BSE2113',
        'subject_name': 'Mobile Software Engineering',
        'lecturer': 'Mdm Fatin',
        'day': 'Monday',
        'start_time': '10:00:00',
        'end_time': '12:00:00',
      });

      expect(timetable.timetableId, 9);
      expect(timetable.roomNodeId, 'L8_N14');
      expect(timetable.roomName, 'Elixr');
      expect(timetable.subjectCode, 'BSE2113');
      expect(timetable.subjectName, 'Mobile Software Engineering');
      expect(timetable.lecturer, 'Mdm Fatin');
      expect(timetable.day, 'Monday');
      expect(timetable.startTime, '10:00:00');
      expect(timetable.endTime, '12:00:00');

      expect(timetable.toJson(), {
        'timetable_id': 9,
        'room_node_id': 'L8_N14',
        'room_name': 'Elixr',
        'subject_code': 'BSE2113',
        'subject_name': 'Mobile Software Engineering',
        'lecturer': 'Mdm Fatin',
        'day': 'Monday',
        'start_time': '10:00:00',
        'end_time': '12:00:00',
      });
    });
  });

  group('ScheduleModel JSON mapping', () {
    test('converts a Supabase my_schedule row correctly', () {
      final schedule = ScheduleModel.fromJson({
        'schedule_id': 'SCH001',
        'user_id': '00000000-0000-0000-0000-000000000002',
        // Also tests PostgreSQL bigint conversion.
        'timetable_id': 9.0,
      });

      expect(schedule.scheduleId, 'SCH001');
      expect(schedule.userId, '00000000-0000-0000-0000-000000000002');
      expect(schedule.timetableId, 9);

      expect(schedule.toJson(), {
        'schedule_id': 'SCH001',
        'user_id': '00000000-0000-0000-0000-000000000002',
        'timetable_id': 9,
      });
    });

    test('accepts nullable schedule relationships', () {
      final schedule = ScheduleModel.fromJson({
        'schedule_id': 'SCH002',
        'user_id': null,
        'timetable_id': null,
      });

      expect(schedule.scheduleId, 'SCH002');
      expect(schedule.userId, isNull);
      expect(schedule.timetableId, isNull);
    });
  });
}
