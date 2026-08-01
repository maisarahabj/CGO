/// Represents one row from the `public.profile` table in Supabase.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.role,
    this.fullName,
    this.unimyId,
    this.dob,
    this.profPic,
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? unimyId;
  final DateTime? dob;
  final String? profPic;
  final String role;
  final DateTime? createdAt;

  /// Converts a Supabase profile row into a ProfileModel.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      unimyId: json['unimy_id'] as String?,
      dob: _parseOptionalDateTime(json['dob']),
      profPic: json['prof_pic'] as String?,
      role: json['role'] as String,
      createdAt: _parseOptionalDateTime(json['created_at']),
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'unimy_id': unimyId,
      'dob': dob?.toIso8601String().split('T').first,
      'prof_pic': profPic,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(value as String);
  }
}
