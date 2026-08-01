/// Represents one row from the `public.visit_histories` table in Supabase.
class VisitHistoryModel {
  const VisitHistoryModel({
    required this.visitId,
    this.userId,
    this.destinationNodeId,
    this.visitedAt,
  });

  final String visitId;
  final String? userId;
  final String? destinationNodeId;
  final DateTime? visitedAt;

  /// Converts one Supabase visit_histories row
  /// into a VisitHistoryModel.
  factory VisitHistoryModel.fromJson(Map<String, dynamic> json) {
    return VisitHistoryModel(
      visitId: json['visit_id'] as String,
      userId: json['user_id'] as String?,
      destinationNodeId: json['destination_node_id'] as String?,
      visitedAt: json['visited_at'] == null
          ? null
          : DateTime.parse(json['visited_at'] as String),
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'visit_id': visitId,
      'user_id': userId,
      'destination_node_id': destinationNodeId,
      'visited_at': visitedAt?.toIso8601String(),
    };
  }
}
