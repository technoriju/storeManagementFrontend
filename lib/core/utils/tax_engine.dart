/// Tax Engine to calculate GST and other taxes
class TaxEngine {
  /// Calculate tax for a given amount
  /// [rate] is the tax percentage (e.g., 18.0 for 18%)
  /// [isInclusive] indicates if the amount already includes the tax
  static double calculateTax(double amount, double rate,
      {bool isInclusive = false}) {
    if (rate <= 0) return 0.0;

    if (isInclusive) {
      // If inclusive: Tax = Amount - (Amount / (1 + (Rate / 100)))
      return amount - (amount / (1 + (rate / 100)));
    } else {
      // If exclusive: Tax = Amount * (Rate / 100)
      return amount * (rate / 100);
    }
  }

  /// Calculate the base amount (amount without tax)
  static double calculateBaseAmount(double amount, double rate,
      {bool isInclusive = false}) {
    if (rate <= 0) return amount;

    if (isInclusive) {
      return amount / (1 + (rate / 100));
    } else {
      return amount;
    }
  }
}
