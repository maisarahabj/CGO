/// Represents one row from the `public.floors` table in Supabase.
class FloorModel {
  const FloorModel({
    required this.floorId,
    this.levelNumber,
    this.floorName,
    this.splineUrl,
    this.isAccessible = true,
  });

  final String floorId;
  final int? levelNumber;
  final String? floorName;
  final String? splineUrl;
  final bool isAccessible;

  /// Human-readable floor text used in destination search results.
  String get displayName {
    final name = floorName?.trim();
    if (name != null && name.isNotEmpty) return name;

    if (floorId.toUpperCase() == 'G') return 'Ground Floor';

    final number =
        levelNumber?.toString() ?? floorId.replaceAll(RegExp(r'[^0-9]'), '');
    return number.isEmpty ? floorId : 'Level $number';
  }

  /// Converts a Supabase floors row into a FloorModel.
  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      floorId: json['floor_id'] as String,
      levelNumber: (json['level_number'] as num?)?.toInt(),
      floorName: json['floor_name'] as String?,
      splineUrl: json['spline_url'] as String?,
      isAccessible: json['is_accessible'] as bool? ?? true,
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'floor_id': floorId,
      'level_number': levelNumber,
      'floor_name': floorName,
      'spline_url': splineUrl,
      'is_accessible': isAccessible,
    };
  }
}
