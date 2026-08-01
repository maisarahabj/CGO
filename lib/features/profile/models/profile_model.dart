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
      fullName: _cleanOptionalText(json['full_name']),
      unimyId: _cleanOptionalText(json['unimy_id']),
      dob: _parseOptionalDateTime(json['dob']),
      profPic: _cleanOptionalText(json['prof_pic']),
      role: (json['role'] as String?)?.trim() ?? '',
      createdAt: _parseOptionalDateTime(json['created_at']),
    );
  }

  /// Alias used by services that refer to a Supabase row as a map.
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel.fromJson(map);
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

  /// Produces initials for the profile-photo fallback.
  ///
  /// "Jane Doe" becomes "JD".
  /// "Jane" becomes "J".
  String get initials {
    final cleanedName = fullName?.trim();

    if (cleanedName == null || cleanedName.isEmpty) {
      return 'U';
    }

    final nameParts = cleanedName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (nameParts.isEmpty) {
      return 'U';
    }

    if (nameParts.length == 1) {
      return nameParts.first[0].toUpperCase();
    }

    final firstInitial = nameParts.first[0];
    final lastInitial = nameParts.last[0];

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  /// UI-friendly name for the `prof_pic` database field.
  String? get profileImageUrl {
    return _cleanOptionalText(profPic);
  }

  static DateTime? _parseOptionalDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static String? _cleanOptionalText(Object? value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
