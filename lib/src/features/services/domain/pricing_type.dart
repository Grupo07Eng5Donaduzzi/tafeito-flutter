/// Mirrors the backend `PricingType` enum (HOURLY/DAILY/MONTHLY).
enum PricingType {
  hourly('HOURLY', 'Por hora'),
  daily('DAILY', 'Por dia'),
  monthly('MONTHLY', 'Por mes');

  const PricingType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PricingType fromApi(String? value) {
    return PricingType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => PricingType.hourly,
    );
  }
}
