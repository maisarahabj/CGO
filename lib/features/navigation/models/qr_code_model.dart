/// Represents one row from the `public.qr_codes` table in Supabase.
class QrCodeModel {
  const QrCodeModel({
    required this.qrId,
    this.nodeId,
    this.qrValue,
    this.locationDescription,
    this.status,
  });

  final String qrId;
  final String? nodeId;
  final String? qrValue;
  final String? locationDescription;
  final String? status;

  /// Indicates whether this QR checkpoint may currently be used.
  bool get isActive => status?.toLowerCase() == 'active';

  /// Converts a Supabase qr_codes row into a QrCodeModel.
  factory QrCodeModel.fromJson(Map<String, dynamic> json) {
    return QrCodeModel(
      qrId: json['qr_id'] as String,
      nodeId: json['node_id'] as String?,
      qrValue: json['qr_value'] as String?,
      locationDescription: json['location_description'] as String?,
      status: json['status'] as String?,
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'qr_id': qrId,
      'node_id': nodeId,
      'qr_value': qrValue,
      'location_description': locationDescription,
      'status': status,
    };
  }
}
