/*
Central role definitions for the CampusGO Flutter application.

These Dart enums mirror the PostgreSQL enums stored in Supabase:

ProfileRole matches public.profile_role_enum:
student, lecturer, admin

FaqTargetRole matches public.faq_target_role_enum:
regular, admin

Supabase returns PostgreSQL enum values to Flutter as JSON strings.
The fromDatabase() methods convert those strings into type-safe Dart
enum values. The databaseValue property converts a Dart enum back into
the exact string required by Supabase.

All features must use these enums instead of manually writing role
strings such as 'student', 'lecturer', 'regular', or 'admin'.

A guest is not a ProfileRole because a guest has no authenticated
profile record. This file only defines the permitted role values;
rules that map profile roles to FAQ audiences should be handled
separately.
*/

/// public.profile_role_enum
enum ProfileRole {
  student('student'),
  lecturer('lecturer'),
  admin('admin');

  const ProfileRole(this.databaseValue);

  /// Exact value stored in Supabase.
  final String databaseValue;

  /// Converts the value returned by Supabase into a Dart enum.
  static ProfileRole fromDatabase(Object? value) {
    for (final role in ProfileRole.values) {
      if (role.databaseValue == value) {
        return role;
      }
    }

    throw FormatException(
      'Unknown profile role received from Supabase: $value',
    );
  }
}

/// public.faq_target_role_enum
enum FaqTargetRole {
  regular('regular'),
  admin('admin');

  const FaqTargetRole(this.databaseValue);

  final String databaseValue;

  /// Converts the value returned by Supabase into a Dart enum.
  static FaqTargetRole fromDatabase(Object? value) {
    for (final role in FaqTargetRole.values) {
      if (role.databaseValue == value) {
        return role;
      }
    }

    throw FormatException(
      'Unknown FAQ target role received from Supabase: $value',
    );
  }
}
