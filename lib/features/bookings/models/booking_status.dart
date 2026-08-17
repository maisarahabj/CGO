enum BookingStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromValue(String value) {
    return BookingStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => throw ArgumentError('Unknown booking status: $value'),
    );
  }

  bool get isActive => this == BookingStatus.pending || this == BookingStatus.approved;
}